resource "aws_kms_key" "lambda_env_key" {
  description             = "KMS key for Lambda environment variable encryption"
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "contact-form-dlq"
  kms_master_key_id        = aws_kms_key.lambda_env_key.arn
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_lambda_function" "contact_form" {
  function_name = "contactFormHandler"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda.zip"
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.contact_submissions.name
    }
  }
  kms_key_arn = aws_kms_key.lambda_env_key.arn
  tracing_config {
    mode = "Active"
  }
  vpc_config {
    subnet_ids         = ["subnet-016d75a19db94996a"]
    security_group_ids = ["sg-026b1f77134d88bd7"]
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
  reserved_concurrent_executions = 5
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role_pipelines_geti0_2025"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_additional_policy" {
  name = "lambda_additional_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.lambda_env_key.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.lambda_dlq.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.contact_submissions.arn
      }
    ]
  })
}
