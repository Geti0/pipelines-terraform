# S3 Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_suffix" {
  description = "Random suffix for bucket naming"
  type        = string
}