# Infrastructure

This directory contains Terraform code and Terratest tests for AWS infrastructure provisioning.

## Structure
- terraform/: Terraform code for S3, CloudFront, API Gateway, Lambda, DynamoDB
- test/terratest/: Go tests for infrastructure coverage

## Quality Checks
- tflint, terraform fmt, terraform validate, Checkov
- Terratest (≥60% coverage)

## Pipeline
- See buildspec-infra.yml
