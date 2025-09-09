resource "aws_dynamodb_table" "contact_submissions" {
  name         = "contact_submissions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
  # Other attributes are stored but not indexed
}
