# PowerShell script to deploy the CodePipeline solution

# Prompt for GitHub token
$githubToken = Read-Host -Prompt "Enter your GitHub personal access token" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken)
$plainGithubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Set environment variable
$env:TF_VAR_github_token = $plainGithubToken

# Navigate to Terraform directory
cd c:\laragon\www\pipelines-terraform\infra\terraform

# Apply Terraform configuration
Write-Host "Applying Terraform configuration with CodePipeline..." -ForegroundColor Green
terraform apply -auto-approve

# Clean up sensitive environment variable
$env:TF_VAR_github_token = $null

Write-Host "Deployment complete! Your AWS CodePipeline has been created." -ForegroundColor Green
Write-Host "Now you can push to your 'develop' branch to trigger the pipeline." -ForegroundColor Yellow
