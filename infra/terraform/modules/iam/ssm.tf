resource "aws_ssm_parameter" "example" {
  name  = "/iam/example"
  type  = "String"
  value = var.ssm_value
}
