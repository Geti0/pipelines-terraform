# Variables for the Terraform configuration

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pipelines-terraform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "deployment_id" {
  description = "Unique deployment identifier"
  type        = string
  default     = "deploy"
}

variable "github_token" {
  description = "GitHub personal access token for CI/CD"
  type        = string
  sensitive   = true
}