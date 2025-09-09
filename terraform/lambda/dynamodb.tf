resource "aws_dynamodb_table" "contact_submissions" {
  name         = "contact_submissions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
  # Other attributes are stored but not indexed
  server_side_encryption {
    enabled     = true
    kms_key_arn = "arn:aws:kms:us-east-2:YOUR_ACCOUNT_ID:key/YOUR_KMS_KEY_ID" # Replace with your KMS key
  }
  point_in_time_recovery {
    enabled = true
  }
}
