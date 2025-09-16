# S3 bucket for website hosting and related resources

resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-website-${var.bucket_suffix}"

  tags = {
    Name        = "${var.project_name}-website"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags,
      website,
      force_destroy,
      logging,
      versioning,
      object_lock_configuration,
      replication_configuration,
      cors_rule,
      server_side_encryption_configuration,
    ]
  }
}

# Enable S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website_encryption" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
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

resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website_pab]
}