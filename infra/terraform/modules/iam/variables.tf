# IAM Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "deployment_id" {
  description = "Unique deployment identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_suffix" {
  description = "Random suffix for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}