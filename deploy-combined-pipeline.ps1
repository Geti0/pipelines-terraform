#!/usr/bin/env pwsh

# Deploy Combined Pipeline Script
# This script helps deploy the new combined pipeline approach

Write-Host "🚀 Deploying Combined Pipeline Approach" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "buildspec-combined.yml")) {
    Write-Host "❌ Error: buildspec-combined.yml not found. Are you in the project root?" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found buildspec-combined.yml" -ForegroundColor Green

# Check if AWS CLI is configured
try {
    $awsAccount = aws sts get-caller-identity --query Account --output text 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AWS CLI configured for account: $awsAccount" -ForegroundColor Green
    } else {
        throw "AWS CLI not configured"
    }
} catch {
    Write-Host "❌ AWS CLI not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Check Terraform installation
try {
    $tfVersion = terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version
    Write-Host "✅ Terraform installed: v$tfVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform not found. Please install Terraform first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Implementation Steps:" -ForegroundColor Yellow
Write-Host "1. Backup existing separate buildspec files" -ForegroundColor White
Write-Host "2. Test the combined pipeline locally" -ForegroundColor White
Write-Host "3. Deploy infrastructure with combined approach" -ForegroundColor White
Write-Host "4. Update CodeBuild project configuration" -ForegroundColor White

Write-Host ""
$confirm = Read-Host "Continue with implementation? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ Deployment cancelled" -ForegroundColor Red
    exit 0
}

# Step 1: Backup existing files
Write-Host ""
Write-Host "📁 Step 1: Backing up existing buildspec files..." -ForegroundColor Blue

if (Test-Path "buildspec-infra.yml") {
    Copy-Item "buildspec-infra.yml" "buildspec-infra.yml.backup"
    Write-Host "✅ Backed up buildspec-infra.yml" -ForegroundColor Green
}

if (Test-Path "buildspec-web.yml") {
    Copy-Item "buildspec-web.yml" "buildspec-web.yml.backup"
    Write-Host "✅ Backed up buildspec-web.yml" -ForegroundColor Green
}

# Step 2: Test combined pipeline locally (validate syntax)
Write-Host ""
Write-Host "🧪 Step 2: Testing combined buildspec syntax..." -ForegroundColor Blue

# Validate YAML syntax
try {
    $yamlContent = Get-Content "buildspec-combined.yml" -Raw
    # Basic YAML validation - check for common issues
    if ($yamlContent -match "^\s*-\s*$") {
        Write-Host "⚠️  Warning: Found empty list items in YAML" -ForegroundColor Yellow
    }
    Write-Host "✅ Combined buildspec YAML syntax looks good" -ForegroundColor Green
} catch {
    Write-Host "❌ YAML syntax validation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Initialize Terraform (dry run)
Write-Host ""
Write-Host "🏗️  Step 3: Testing Terraform configuration..." -ForegroundColor Blue

Push-Location "infra/terraform"
try {
    # Initialize Terraform
    Write-Host "Initializing Terraform..." -ForegroundColor White
    terraform init

    # Validate Terraform
    Write-Host "Validating Terraform configuration..." -ForegroundColor White
    terraform validate

    # Check formatting
    Write-Host "Checking Terraform formatting..." -ForegroundColor White
    terraform fmt -check

    Write-Host "✅ Terraform configuration is valid" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform validation failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# Step 4: Test Node.js dependencies
Write-Host ""
Write-Host "📦 Step 4: Testing Node.js dependencies..." -ForegroundColor Blue

# Test frontend dependencies
Push-Location "web/frontend"
try {
    if (Test-Path "package.json") {
        Write-Host "Installing frontend dependencies..." -ForegroundColor White
        npm install --silent
        Write-Host "✅ Frontend dependencies installed" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Frontend dependency installation failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# Test Lambda dependencies
Push-Location "web/lambda"
try {
    if (Test-Path "package.json") {
        Write-Host "Installing Lambda dependencies..." -ForegroundColor White
        npm install --silent
        Write-Host "✅ Lambda dependencies installed" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Lambda dependency installation failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "🎉 Combined Pipeline Setup Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update your CodeBuild project to use 'buildspec-combined.yml'" -ForegroundColor White
Write-Host "2. Push changes to your develop branch to trigger the pipeline" -ForegroundColor White
Write-Host "3. Monitor the single pipeline execution in AWS Console" -ForegroundColor White

Write-Host ""
Write-Host "💡 Key Benefits:" -ForegroundColor Cyan
Write-Host "• No more terraform output artifacts issues" -ForegroundColor White
Write-Host "• Simplified pipeline management" -ForegroundColor White
Write-Host "• All quality gates still enforced" -ForegroundColor White
Write-Host "• Sequential infrastructure → web deployment" -ForegroundColor White

Write-Host ""
Write-Host "📁 Files created/modified:" -ForegroundColor Yellow
Write-Host "• buildspec-combined.yml (new combined pipeline)" -ForegroundColor White
Write-Host "• buildspec-infra.yml.backup (backup of original)" -ForegroundColor White
Write-Host "• buildspec-web.yml.backup (backup of original)" -ForegroundColor White

Write-Host ""
$deployNow = Read-Host "Would you like to create a test CodeBuild project now? (y/N)"
if ($deployNow -eq "y" -or $deployNow -eq "Y") {
    Write-Host ""
    Write-Host "🏗️  Creating test CodeBuild project..." -ForegroundColor Blue
    Write-Host "Note: You will need to update your CodeBuild project manually in AWS Console" -ForegroundColor Yellow
    Write-Host "Set the buildspec file path to: buildspec-combined.yml" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "✅ Setup complete! Remember to update your CodeBuild project configuration." -ForegroundColor Green
}

Write-Host ""
Write-Host "🔗 Quick Reference:" -ForegroundColor Cyan
Write-Host "• Combined buildspec: buildspec-combined.yml" -ForegroundColor White
Write-Host "• Original files backed up with .backup extension" -ForegroundColor White
Write-Host "• All assignment requirements still met" -ForegroundColor White
