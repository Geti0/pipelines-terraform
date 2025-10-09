resource "aws_ssm_parameter" "example" {
  name      = "/dynamodb/example"
  type      = "String"
  value     = var.ssm_value
  overwrite = true
}
