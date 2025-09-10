package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformValidation(t *testing.T) {
	// This test validates terraform configuration without applying
	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		NoColor:      true,
	}

	// Validate the Terraform configuration
	terraform.Validate(t, terraformOptions)
}

func TestTerraformFormat(t *testing.T) {
	// This test checks terraform formatting
	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		NoColor:      true,
	}

	// Check if Terraform files are formatted correctly
	terraform.RunTerraformCommand(t, terraformOptions, "fmt", "-check")
}

func TestTerraformInfrastructure(t *testing.T) {
	// Only run integration test if explicitly enabled
	if os.Getenv("RUN_INTEGRATION_TESTS") != "true" {
		t.Skip("Integration test skipped - set RUN_INTEGRATION_TESTS=true to enable")
	}
	
	// Define the Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		NoColor:      true,
		Vars: map[string]interface{}{
			"aws_region":     "us-east-1",
			"project_name":   "test-pipelines",
			"environment":    "test",
			"deployment_id":  "terratest",
		},
	}

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply"
	terraform.InitAndApply(t, terraformOptions)

	// Test S3 bucket exists and is configured correctly
	bucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, bucketName, "S3 bucket name should not be empty")
	
	// Verify S3 bucket exists in AWS
	awsRegion := "us-east-1"
	aws.AssertS3BucketExists(t, awsRegion, bucketName)

	// Test CloudFront distribution exists
	cloudFrontDistributionId := terraform.Output(t, terraformOptions, "cloudfront_distribution_id")
	assert.NotEmpty(t, cloudFrontDistributionId, "CloudFront distribution ID should not be empty")

	cloudFrontDomain := terraform.Output(t, terraformOptions, "cloudfront_domain_name")
	assert.NotEmpty(t, cloudFrontDomain, "CloudFront domain should not be empty")
	assert.Contains(t, cloudFrontDomain, "cloudfront.net", "CloudFront domain should contain cloudfront.net")

	// Test API Gateway URL exists
	apiGatewayUrl := terraform.Output(t, terraformOptions, "api_gateway_url")
	assert.NotEmpty(t, apiGatewayUrl, "API Gateway URL should not be empty")
	assert.Contains(t, apiGatewayUrl, "amazonaws.com", "API Gateway URL should contain amazonaws.com")

	// Test DynamoDB table exists
	dynamoTableName := terraform.Output(t, terraformOptions, "dynamodb_table_name")
	assert.NotEmpty(t, dynamoTableName, "DynamoDB table name should not be empty")
	
	// Verify DynamoDB table exists using a simple check
	// Note: In a real environment, we could use AWS SDK directly for more detailed validation
	assert.Contains(t, dynamoTableName, "terraform-lock", "DynamoDB table should contain terraform-lock in name")
}
