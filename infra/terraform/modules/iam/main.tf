# Standalone IAM policies for CI/CD Pipeline

# IAM Policy for CI/CD Pipeline Access to Parameter Store
resource "aws_iam_policy" "pipeline_parameter_store_policy" {
  name        = "${var.project_name}-${var.deployment_id}-pipeline-parameter-store-policy-${var.resource_suffix}"
  description = "Policy to allow CI/CD pipeline to read/write Parameter Store values"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:GetParameterHistory"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/pipelines-terraform/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-pipeline-parameter-store-policy"
    Environment = var.environment
    Purpose     = "CI/CD Parameter Store Access"
  }
}