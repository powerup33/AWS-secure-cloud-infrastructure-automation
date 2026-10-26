output "project_details" {
  description = "Project name and environment"
  value = {
    project_name = var.project_name
    environment  = var.environment
    aws_region   = var.aws_region
  }
}
