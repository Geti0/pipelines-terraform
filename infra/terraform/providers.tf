# Terraform configuration and providers

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Remote state backend - prevents state conflicts and enables collaboration
  # Uncomment and configure when ready to use remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "pipelines-terraform/terraform.tfstate"
  #   region = "eu-north-1"
  #   
  #   # Optional: DynamoDB table for state locking
  #   # dynamodb_table = "terraform-state-lock"
  #   # encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source_dir  = "../../web/lambda/src"

  # Exclude test files and development artifacts
  excludes = [
    "tests",
    "coverage",
    "*.test.js",
    "jest.config.js",
    "eslint.config.js",
    ".env*",
    "node_modules",
  ]
}