# PowerShell script to deploy the CodePipeline solution

# Navigate to Terraform directory
cd c:\laragon\www\pipelines-terraform\infra\terraform

# Make sure you've added your GitHub token to terraform.tfvars first!
$tfvarsContent = Get-Content -Path "terraform.tfvars" -Raw
if ($tfvarsContent -match "YOUR_TOKEN_HERE") {
    Write-Host "ERROR: You need to edit terraform.tfvars and add your GitHub token first!" -ForegroundColor Red
    Write-Host "Open the file and replace 'YOUR_TOKEN_HERE' with your actual GitHub token" -ForegroundColor Red
    exit 1
}

# Apply Terraform configuration
Write-Host "Applying Terraform configuration with CodePipeline..." -ForegroundColor Green
terraform apply -auto-approve

Write-Host "Deployment complete! Your AWS CodePipeline has been created." -ForegroundColor Green
Write-Host "Now you can push to your 'main' branch to trigger the pipeline." -ForegroundColor Yellow
