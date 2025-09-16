resource "aws_ssm_parameter" "example" {
  name      = "/s3/example"
  type      = "String"
  value     = var.ssm_value
  overwrite = true
}
