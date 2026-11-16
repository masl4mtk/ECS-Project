variable "image_tag" {
  description = "Tag of the images in ECR"
  type        = string
  default     = "latest"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}
