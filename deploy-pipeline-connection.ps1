# PowerShell script to deploy the CodePipeline solution

# Navigate to Terraform directory
cd c:\laragon\www\pipelines-terraform\infra\terraform

# Apply Terraform configuration
Write-Host "Applying Terraform configuration with CodePipeline..." -ForegroundColor Green
terraform apply -auto-approve

Write-Host "Deployment complete! Your AWS CodePipeline has been created." -ForegroundColor Green
Write-Host "IMPORTANT: You need to complete the GitHub connection!" -ForegroundColor Yellow
Write-Host "1. Go to AWS Console → Developer Tools → Settings → Connections" -ForegroundColor Yellow
Write-Host "2. Find your connection (pipelines-terraform-*)" -ForegroundColor Yellow
Write-Host "3. Click 'Update pending connection'" -ForegroundColor Yellow
Write-Host "4. Follow the steps to authorize AWS to access your GitHub repository" -ForegroundColor Yellow
Write-Host "5. After connection is complete, you can push to your main branch to trigger the pipeline" -ForegroundColor Yellow
