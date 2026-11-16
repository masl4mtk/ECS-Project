variable "domain_name" {
  description = "name of domain used for this project"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of Load Balancer"
  type        = string
}
