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
    kms_key_arn = "arn:aws:kms:us-east-1:479324457009:key/85888b48-53c4-4b39-a2f8-a95a97eedd81"
  }
  tracing_config {
    mode = "Active"
  }
  vpc_config {
    subnet_ids         = ["subnet-016d75a19db94996a"]
    security_group_ids = ["sg-026b1f77134d88bd7"]
  }
  dead_letter_config {
    target_arn = "arn:aws:sqs:us-east-2:YOUR_ACCOUNT_ID:YOUR_DLQ" # Replace with your DLQ ARN
  }
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:us-east-2:YOUR_ACCOUNT_ID:code-signing-config:YOUR_CONFIG_ID" # Replace with your code signing config
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
