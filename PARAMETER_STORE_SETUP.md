# Parameter Store IAM Policy Setup

## Manual IAM Policy Attachment

If the Terraform pipeline fails due to IAM user management conflicts, apply this policy manually:

### Step 1: Get the Policy ARN
After the infrastructure pipeline runs successfully, it will output:
```
pipeline_parameter_store_policy_arn = "arn:aws:iam::479324457009:policy/pipelines-terraform-deploy-pipeline-parameter-store-policy-XXXXXXXX"
```

### Step 2: Attach Policy to Existing User

#### Option A: AWS CLI
```bash
aws iam attach-user-policy \
  --user-name pipelines-terraform \
  --policy-arn "arn:aws:iam::479324457009:policy/pipelines-terraform-deploy-pipeline-parameter-store-policy-XXXXXXXX"
```

#### Option B: AWS Console
1. Go to IAM Console → Users → pipelines-terraform
2. Click "Add permissions" → "Attach policies directly"
3. Search for: `pipelines-terraform-deploy-pipeline-parameter-store-policy`
4. Select and attach the policy

#### Option C: Terraform Data Source (Alternative)
Create a separate Terraform file for IAM management:

```hcl
# iam-policy-attachment.tf
data "aws_iam_policy" "parameter_store_policy" {
  name = "pipelines-terraform-deploy-pipeline-parameter-store-policy-XXXXXXXX"
}

data "aws_iam_user" "pipeline_user" {
  user_name = "pipelines-terraform"
}

resource "aws_iam_user_policy_attachment" "pipeline_parameter_store" {
  user       = data.aws_iam_user.pipeline_user.user_name
  policy_arn = data.aws_iam_policy.parameter_store_policy.arn
}
```

### Step 3: Verify Permissions
Test the permissions:
```bash
aws ssm describe-parameters --region eu-north-1
aws ssm get-parameter --name "/pipelines-terraform/test" --region eu-north-1
```

## Required Permissions

The Parameter Store policy grants these permissions:
- `ssm:GetParameter` - Read parameter values
- `ssm:PutParameter` - Store parameter values  
- `ssm:DescribeParameters` - List parameters
- `ssm:GetParameterHistory` - View parameter history
- `ssm:DeleteParameter` - Clean up parameters

Scope: Limited to `/pipelines-terraform/*` namespace for security.
