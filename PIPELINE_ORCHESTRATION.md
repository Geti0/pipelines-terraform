# AWS CI/CD Pipeline Orchestration

## CodePipeline Orchestration Solution

This project now includes AWS CodePipeline orchestration to solve the dependency issue between the infrastructure and web pipelines. The implementation:

1. Creates a CodePipeline that orchestrates both pipelines in sequence
2. Ensures infrastructure is fully deployed before web deployment starts
3. Maintains the separation of concerns between infrastructure and application code
4. Follows enterprise best practices for CI/CD pipeline orchestration

## How the Solution Works

The implementation adds a `codepipeline.tf` file to your Terraform configuration that:

1. Creates an S3 bucket for pipeline artifacts
2. Sets up IAM roles for CodePipeline and both CodeBuild projects
3. Defines two CodeBuild projects (for infrastructure and web)
4. Creates a CodePipeline with three stages:
   - Source: Gets code from GitHub using CodeStar Connections
   - DeployInfrastructure: Runs the infrastructure pipeline
   - DeployWebApplication: Runs the web pipeline (only after infrastructure succeeds)

## Deployment Instructions

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed (v1.0+)
- GitHub personal access token with repo permissions

### Steps to Deploy

1. **Add your GitHub token to the variables file**

   Edit the `infra/terraform/terraform.tfvars` file and replace `YOUR_TOKEN_HERE` with your GitHub personal access token:

   ```
   github_token = "your-actual-token-here"
   ```
   
   **IMPORTANT**: Make sure your token is exactly 40 characters (a standard GitHub token length)
   and contains only the token itself - no quotes or extra characters.

2. **Run the deployment script**

   ```powershell
   .\deploy-with-token.ps1
   ```
   
   This script will verify your token is set and apply the Terraform configuration.

3. **Commit and push to your `main` branch**

   This will automatically trigger the CodePipeline, which will:
   1. Pull your source code
   2. Run the infrastructure pipeline to completion
   3. Only then run the web pipeline

## Verification

After deployment, you can verify the solution by:

1. Checking the AWS CodePipeline console to see the pipeline stages executing in sequence
2. Confirming that the web pipeline no longer fails due to missing terraform outputs
3. Validating that the website is deployed successfully to S3 and accessible via CloudFront

## Why This Solution Works

This implementation solves the race condition by ensuring that:

1. Infrastructure pipeline runs to completion first
2. All AWS resources are created and terraform outputs are available
3. Web pipeline only starts after infrastructure pipeline succeeds
4. Web pipeline can now successfully access all required terraform outputs

This orchestration pattern is an industry standard approach for handling dependencies between infrastructure and application deployments.

## Additional Notes

- No changes were needed to your existing buildspec files
- The solution maintains the separation between infrastructure and application code
- You can still run either pipeline independently if needed
- Proper error handling ensures that if infrastructure fails, web deployment won't attempt to run
