# Lambda Module Outputs

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.contact_form.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.contact_form.arn
}

output "invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = aws_lambda_function.contact_form.invoke_arn
}