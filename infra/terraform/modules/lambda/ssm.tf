resource "aws_ssm_parameter" "example" {
  name      = "/lambda/example"
  type      = "String"
  value     = var.ssm_value
  overwrite = true
}
