# Main Terraform configuration

provider "aws" {
  region = "us-east-1"
}

module "website" {
  source = "./lambda"
}
