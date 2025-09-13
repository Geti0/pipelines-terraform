# Shared random resources used across multiple infrastructure components
# These resources are stable and will not force recreation unless explicitly needed

resource "random_id" "bucket_suffix" {
  byte_length = 4

  # Stable keepers - only change these when you actually need new resources
  keepers = {
    # Only change this if you want to force recreation of S3 bucket
    bucket_generation = "v1"
  }
}

resource "random_id" "resource_suffix" {
  byte_length = 4

  # Stable keepers - only change these when you actually need new resources  
  keepers = {
    # Only change this if you want to force recreation of all resources
    infrastructure_generation = "v1"
  }
}