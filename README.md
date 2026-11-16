# OrderFlow: event-driven order system on AWS ECS Fargate

OrderFlow is a small three-service application (frontend, API, worker) deployed on **AWS ECS Fargate** with Terraform, served over HTTPS on a custom domain, and delivered by three GitHub Actions pipelines that authenticate to AWS with OIDC (no long-lived keys).

The application is deliberately simple. The point of the project is the infrastructure and delivery around it.

## How it works

```
Browser
   |  HTTPS (443)            HTTP (80) is redirected to HTTPS
   v
Application Load Balancer  (ACM certificate, Route 53 alias record)
   |-- /api/*  -->  API target group       -->  api service      (port 3000)
   |-- default -->  frontend target group  -->  frontend service (port 8080)

api service     --> saves the order to RDS PostgreSQL as PENDING
                --> sends {orderId} to the SQS queue
worker service  --> polls SQS, sets PROCESSING, then COMPLETED or FAILED
                --> failed messages go to a dead-letter queue after 3 receives
```

- The page polls `/api/orders` every 2 seconds, so you can watch an order move from PENDING to COMPLETED.
- The three services never call each other directly. The queue decouples the API from the worker.
- Entering the customer name `fail` triggers a simulated failure, which shows the retries and the dead-letter queue.

## Project structure

```
.
├── app/
│   ├── api/                  Express API (Dockerfile, server.js)
│   ├── worker/               SQS consumer (Dockerfile, worker.js)
│   ├── frontend/             Static page served by nginx (Dockerfile, index.html)
│   │   └── nginx.local.conf  Proxy config used by Docker Compose only
│   └── elasticmq/            Local SQS emulator config for Compose
├── modules/
│   ├── networking/           VPC, subnets, NAT, route tables, security groups
│   ├── load-balancer/        ALB, target groups, HTTPS listener, HTTP redirect
│   ├── Route53/              ACM certificate, DNS validation, alias record
│   ├── ECR/                  Image repositories (one per service)
│   ├── ECS/                  Cluster, task definitions, services, log groups
│   ├── IAM/                  Task execution role and per-service task roles
│   ├── RDS/                  PostgreSQL instance and Secrets Manager password
│   └── SQS/                  Orders queue and dead-letter queue
├── bootstrap/                S3 state bucket and the GitHub Actions OIDC role
├── .github/workflows/        The three pipelines (see below)
├── docker-compose.yaml       Local environment
├── main.tf                   Root module wiring the modules together
├── terraform.tf              Terraform and provider versions, S3 backend
├── .env.example              Variables for local Compose (copy to .env)
└── README.md
```

## Run it locally

Requirements: Docker with Compose.

```bash
cp .env.example .env        # then set real values for the three variables
docker compose up --build
```

Open <http://localhost:8080>. The local environment runs PostgreSQL and ElasticMQ (an SQS-compatible emulator) alongside the three services, with a named volume for the database. Stop it with `docker compose down` (add `-v` to remove the database volume).

## Container images

- Multi-stage builds, pinned base image tags, and `.dockerignore` files.
- The API and worker run as the non-root `node` user. The frontend uses the unprivileged nginx image (port 8080).
- No secrets are baked into images. Locally they come from `.env`. On AWS the database password comes from Secrets Manager and is injected by ECS at runtime.

## Infrastructure (Terraform)

- Modules for networking, load balancer, DNS and certificate, ECR, ECS, IAM, RDS and SQS.
- Two public and two private subnets across two availability zones, with a single NAT gateway for outbound access from the private subnets.
- Fargate tasks run in private subnets. Only the load balancer is public.
- Security groups: the ALB accepts 80 and 443 from anywhere; tasks accept traffic only from the ALB; the database accepts 5432 only from the task security groups.
- Per-service IAM task roles (the API can send to SQS, the worker can receive and delete) and one shared execution role.
- Remote state in S3 with native state locking (`use_lockfile`).
- `for_each` and `locals` keep the three services and the repositories DRY.

### Prerequisites to deploy your own copy

1. An AWS account and AWS credentials for the first manual steps.
2. A domain you own, with a public Route 53 hosted zone for the name you want to use (for example `orderflow.example.com`). If the domain is registered elsewhere, delegate the subdomain to Route 53 with NS records.
3. Change the state bucket name in `terraform.tf` (bucket names are global), and create the bucket once from `bootstrap/`.
4. Apply `bootstrap/` to create the GitHub Actions OIDC role. It references the GitHub OIDC provider that already exists in the account, so create the provider first if your account doesn't have it. Update the repository condition in its trust policy to match your own repository.
5. In your GitHub repository, set these Actions variables: `AWS_ROLE_ARN` (the role created above) and `DOMAIN_NAME` (your domain). Create an environment named `production` with a required reviewer, which gates deployments.

## Pipelines (GitHub Actions)

All three authenticate with OIDC (`aws-actions/configure-aws-credentials`) and assume a role that is trusted only for this repository.

| Pipeline | Trigger | What it does |
|---|---|---|
| **Image build and push** | Push to `main` that changes `app/**`, or manual | Creates the ECR repositories (`terraform apply -target=module.ecr`), then builds the three images and pushes them tagged with the commit SHA |
| **Plan and validate** | Pull request, push to `feature/**`, or manual | `terraform fmt`, `validate`, `tflint`, Trivy configuration scan, then `terraform plan` |
| **Deploy** | Manual, with the image tag (commit SHA) as input | `terraform plan`, then `terraform apply` after manual approval through the `production` environment |

Deploying a version means giving the deploy pipeline the commit SHA of images that already exist in ECR. That tag flows into Terraform through the `image_tag` variable, so every running version traces back to a commit.

## Design decisions and trade-offs

- **Repositories created in the image pipeline with `-target`.** The repositories must exist before images can be pushed, and the images must exist before ECS can start tasks. Creating only the ECR module first breaks that cycle.
- **Plan artifact retention is one day.** Plan files can contain sensitive values, so they are kept briefly.
- **The CI role has broad service permissions** (for example `iam:*`, `ec2:*`). That is acceptable for a demo; in production they would be scoped to specific resources.
- **Trivy runs in report-only mode** (`exit-code: 0`). Findings are visible but do not block the pipeline; tightening that is a later step.
- **Single NAT gateway** keeps the cost down. A production setup would use one per availability zone.
- **Public ALB, private tasks.** TLS ends at the load balancer; traffic to the tasks inside the VPC is plain HTTP.

## Cost and cleanup

The NAT gateway, load balancer and RDS instance bill by the hour. When you are finished:

```bash
terraform destroy
```

The state bucket and the OIDC role in `bootstrap/` are intentionally kept, so the pipelines can deploy again later.
