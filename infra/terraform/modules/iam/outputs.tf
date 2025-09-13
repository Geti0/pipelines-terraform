# IAM Module Outputs

output "pipeline_parameter_store_policy_arn" {
  description = "ARN of the Parameter Store policy for CI/CD pipelines"
  value       = aws_iam_policy.pipeline_parameter_store_policy.arn
}