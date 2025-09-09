package terratest

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformLambdaModule(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../../terraform/lambda",
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Example: Check if DynamoDB table exists
	tableName := terraform.Output(t, terraformOptions, "contact_submissions_table_name")
	if tableName == "" {
		t.Fatalf("DynamoDB table name output is empty")
	}

	// Add more resource checks as needed for coverage
}
