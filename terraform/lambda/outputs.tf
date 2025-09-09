output "s3_bucket_name" {
  value = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website_cdn.id
}

output "contact_submissions_table_name" {
  value = aws_dynamodb_table.contact_submissions.name
}

output "lambda_function_name" {
  value = aws_lambda_function.contact_form.function_name
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.contact_api.id
}
