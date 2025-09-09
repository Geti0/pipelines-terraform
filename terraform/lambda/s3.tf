resource "aws_s3_bucket" "website" {
  bucket = "my-website-hosting-bucket-geti0-2025"
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
