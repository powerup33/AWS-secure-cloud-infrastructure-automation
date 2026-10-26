variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name used to identify this portfolio project"
  type        = string
  default     = "AWS-secure-cloud-infrastructure-automation"
}

variable "environment" {
  description = "Environment for this infrastructure"
  type        = string
  default     = "dev"
}
