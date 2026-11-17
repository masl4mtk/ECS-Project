# OrderFlow on AWS ECS Fargate

A small order system made of three services (frontend, API, worker), deployed to AWS ECS Fargate with Terraform. It runs over HTTPS on my own domain, and three GitHub Actions pipelines build and deploy it.

I built this to practise Docker, Terraform and CI/CD together. The app itself is simple on purpose. Most of the work is in the infrastructure and the pipelines.

## How it works

```
Browser
   |  HTTPS (443), HTTP (80) redirects to HTTPS
   v
Application Load Balancer (ACM certificate, Route 53 alias record)
   |-- /api/*  -> API target group      -> api service      (port 3000)
   |-- default -> frontend target group -> frontend service (port 8080)

api      saves the order to RDS PostgreSQL as PENDING, then sends the order ID to SQS
worker   reads from SQS, sets PROCESSING, then COMPLETED or FAILED
         messages that fail 3 times go to a dead-letter queue
```

The page checks `/api/orders` every 2 seconds, so you can watch an order go from PENDING to COMPLETED. The services never call each other directly, they only talk through the queue. If you enter the customer name `fail`, the worker fails the order on purpose, which lets you see the retries and the dead-letter queue.

## Project structure

```
.
├── app/
│   ├── api/                  Express API
│   ├── worker/               SQS consumer
│   ├── frontend/             Static page served by nginx
│   └── elasticmq/            Local SQS emulator config (Compose only)
├── modules/
│   ├── networking/           VPC, subnets, NAT, security groups
│   ├── load-balancer/        ALB, target groups, listeners
│   ├── Route53/              ACM certificate, DNS validation, alias record
│   ├── ECR/                  One image repository per service
│   ├── ECS/                  Cluster, task definitions, services, log groups
│   ├── IAM/                  Execution role and per-service task roles
│   ├── RDS/                  PostgreSQL and the Secrets Manager password
│   └── SQS/                  Orders queue and dead-letter queue
├── bootstrap/                State bucket and the GitHub Actions OIDC role
├── .github/workflows/        The three pipelines
├── docker-compose.yaml       Local environment
├── main.tf                   Root module
├── terraform.tf              Versions and S3 backend
└── .env.example              Variables for local Compose
```

## Running it locally

You need Docker with Compose.

```bash
cp .env.example .env     # fill in the three values
docker compose up --build
```

Then open http://localhost:8080. Compose starts PostgreSQL and ElasticMQ (an SQS-compatible emulator) next to the three services. `docker compose down -v` stops everything and removes the database volume.

## Docker images

- Multi-stage builds, pinned base image tags and a `.dockerignore` for each service.
- The API and worker run as the non-root `node` user. The frontend uses the unprivileged nginx image on port 8080.
- No secrets are in the images. Locally they come from `.env`. On AWS the database password is stored in Secrets Manager and ECS passes it to the container at startup.

## Infrastructure

- Two public and two private subnets across two availability zones, with one NAT gateway for outbound traffic from the private subnets.
- Fargate tasks sit in the private subnets. Only the load balancer is public.
- Security groups: the ALB allows 80 and 443 from anywhere, the tasks only accept traffic from the ALB, and the database only accepts port 5432 from the tasks.
- Each service has its own IAM task role (the API can send to SQS, the worker can receive and delete). They share one execution role.
- Terraform state is in S3 with native locking (`use_lockfile`).

### Deploying your own copy

1. You need an AWS account and credentials for the first manual steps.
2. You need a domain with a public Route 53 hosted zone for the name you want to use. If the domain is registered somewhere else, add NS records there pointing the subdomain to Route 53.
3. Change the state bucket name in `terraform.tf` (bucket names are global) and create the bucket from `bootstrap/`.
4. Apply `bootstrap/` to create the GitHub Actions role. It uses the GitHub OIDC provider that already exists in my account, so create that provider first if you don't have one, and change the repository in the trust policy to yours.
5. In the GitHub repository, add two Actions variables: `AWS_ROLE_ARN` (the role from step 4) and `DOMAIN_NAME`. Also create an environment called `production` with a required reviewer, since that is the approval step for deployments.

## Pipelines

All three log in to AWS with OIDC, so there are no access keys stored in GitHub. The role can only be assumed from this repository.

| Pipeline | When it runs | What it does |
|---|---|---|
| Image build and push | Push to `main` that changes `app/**` or `modules/ECR/**`, or manually | Creates the ECR repositories, then builds the three images and pushes them tagged with the commit SHA |
| Plan and validate | Pull request, push to `feature/**`, or manually | Runs `terraform fmt`, `validate`, `tflint`, a Trivy scan, then `terraform plan` |
| Deploy | After a successful image build and push | Runs `terraform plan` with the new image tag, waits for approval on the `production` environment, then runs `terraform apply` |

Every image is tagged with the commit SHA. When the image pipeline finishes, the deploy pipeline starts on its own and gives Terraform the same SHA as `image_tag`, so the running version always matches a commit. Nothing has to be typed in by hand.

## Decisions and trade-offs

- **ECR is created inside the image pipeline** with `terraform apply -target=module.ecr`. The repositories have to exist before images can be pushed, and the images have to exist before ECS can start tasks, so I create the repositories first.
- **Plan artifacts are kept for one day**, because plan files can contain sensitive values.
- **The CI role has broad permissions** (for example `iam:*` and `ec2:*`). That is fine for a demo, but in a real setup I would limit it to specific resources.
- **Trivy only reports.** It uses `exit-code: 0`, so findings show up in the logs but don't fail the pipeline. Making it block is something I'd add next.
- **One NAT gateway** to keep the cost down. For production I'd use one per availability zone.
- **TLS ends at the load balancer.** Traffic between the ALB and the tasks inside the VPC is plain HTTP.
- **Terraform-only changes don't trigger a deploy yet.** The deploy pipeline starts from the image pipeline, so a change that doesn't touch `app/` or `modules/ECR/` won't start it.

## Cost and cleanup

The NAT gateway, load balancer and RDS instance are billed by the hour, so destroy the stack when you're done:

```bash
terraform destroy
```

The state bucket and the OIDC role in `bootstrap/` stay, so the pipelines can deploy again later.
