resource "aws_ssm_parameter" "example" {
  name  = "/api-gateway/example"
  type  = "String"
  value = var.ssm_value
}
