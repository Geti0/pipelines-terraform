# DynamoDB table for contact form submissions

resource "aws_dynamodb_table" "contact_submissions" {
  name         = "${var.project_name}-${var.deployment_id}-contact-submissions-${var.resource_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.deployment_id}-contact-submissions-${var.resource_suffix}"
    Environment = var.environment
  }

  # Critical: Prevent accidental deletion or recreation of DynamoDB table
  lifecycle {
    prevent_destroy = true

    # Ignore changes to these non-critical attributes
    ignore_changes = [
      # Point-in-time recovery can be managed separately
      point_in_time_recovery,
      # Tags can change without recreation
      tags,
    ]
  }
}