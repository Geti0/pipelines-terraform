resource "aws_sns_topic" "s3_notifications" {
  name              = "s3-bucket-notifications"
  kms_master_key_id = aws_kms_key.lambda_env_key.arn
}

resource "aws_s3_bucket" "website" {
  bucket = "my-website-hosting-bucket-geti0-2025"
  logging {
    target_bucket = "my-website-logs-bucket"
    target_prefix = "s3-logs/"
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "arn:aws:kms:us-east-1:479324457009:key/85888b48-53c4-4b39-a2f8-a95a97eedd81"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  lifecycle_rule {
    id      = "expire-objects"
    enabled = true
    expiration {
      days = 365
    }
  }
  replication_configuration {
    role = "arn:aws:iam::479324457009:user/pipelines-terraform"
    rules {
      id     = "replicate-objects"
      status = "Enabled"
      destination {
        bucket        = "arn:aws:s3:::YOUR_DESTINATION_BUCKET"
        storage_class = "STANDARD"
      }
      filter {
        prefix = ""
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.website.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}
