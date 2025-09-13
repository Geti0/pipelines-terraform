# Shared Resource Outputs

output "bucket_suffix" {
  description = "Random suffix for bucket naming"
  value       = random_id.bucket_suffix.hex
}

output "resource_suffix" {
  description = "Random suffix for resource naming"
  value       = random_id.resource_suffix.hex
}