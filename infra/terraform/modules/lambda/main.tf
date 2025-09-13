# Lambda function and related IAM resources for contact form

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.deployment_id}-lambda-exec-role-${var.resource_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach X-Ray permissions
resource "aws_iam_role_policy_attachment" "lambda_xray_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-${var.deployment_id}-lambda-dynamodb-policy-${var.resource_suffix}"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "contact_form" {
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-${var.deployment_id}-contact-form-${var.resource_suffix}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = var.lambda_zip_hash

  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Add timeout configuration - reduced for faster deployment
  timeout     = 5   # 5 seconds (reduced from 10)
  memory_size = 128 # 128 MB (reduced from 256)

  # Reserved concurrency removed due to AWS account limits
  # reserved_concurrent_executions = 10

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  # Lifecycle management to prevent unnecessary recreation
  lifecycle {
    # Don't recreate if only these attributes change
    ignore_changes = [
      # Ignore changes to filename if source_code_hash is being used
      filename,
    ]

    # Always create the new resource before destroying the old one
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execution_arn
}