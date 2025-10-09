resource "aws_ssm_parameter" "example" {
  name      = "/cloudfront/example"
  type      = "String"
  value     = var.ssm_value
  overwrite = true
}
