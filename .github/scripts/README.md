# GitHub Actions Scripts

This directory contains reusable scripts that simplify the GitHub Actions pipelines by extracting complex logic into modular, testable components.

## Scripts Overview

### 🔧 Infrastructure Scripts

#### `store-infrastructure-outputs.sh`
Extracts Terraform outputs and stores them in AWS Parameter Store.

**Usage:**
```bash
./store-infrastructure-outputs.sh [terraform-directory]
```

**Features:**
- Automatically extracts all infrastructure outputs
- Validates outputs before storing
- Stores in standardized Parameter Store paths
- Provides detailed logging and error handling
- Color-coded output for better readability

#### `retrieve-infrastructure-data.sh`
Retrieves infrastructure data from AWS Parameter Store and exports as environment variables.

**Usage:**
```bash
./retrieve-infrastructure-data.sh
```

**Features:**
- Retrieves all infrastructure parameters
- Exports to GitHub Actions environment
- Fallback to shell environment for local testing
- Comprehensive error handling

### 🎯 Quality & Deployment Scripts

#### `quality-checks.sh`
Runs quality checks for different parts of the project.

**Usage:**
```bash
./quality-checks.sh [terraform|frontend|lambda|all]
```

**Features:**
- Modular quality checks for each component
- Terraform: format, validation, TFLint, Checkov
- Frontend: ESLint, tests with coverage
- Lambda: ESLint, tests with coverage
- Can run all checks or specific component checks

#### `deploy-application.sh`
Handles the complete web application deployment process.

**Usage:**
```bash
./deploy-application.sh
```

**Features:**
- Builds frontend with environment configuration
- Deploys Lambda function with retry logic
- Deploys frontend to S3 with CloudFront invalidation
- Comprehensive error handling and status tracking
- Lambda deployment with proper state management

## Benefits

### 🚀 **Simplified Pipelines**
- **Before**: 200+ lines of complex pipeline code
- **After**: Clean, readable pipeline files with ~50 lines each

### 🔄 **Reusability**
- Scripts can be used across different pipelines
- Easy to test locally outside of GitHub Actions
- Modular design allows mixing and matching

### 🛠️ **Maintainability**
- Complex logic isolated in dedicated scripts
- Better error handling and logging
- Easier to debug and update

### 🧪 **Testability**
- Scripts can be tested independently
- Local development and testing support
- Clear input/output interfaces

## Script Standards

All scripts follow these standards:

### 🎨 **Consistent Logging**
- Color-coded output (info, success, warning, error)
- Emoji indicators for better visibility
- Structured logging format

### 🔒 **Error Handling**
- `set -euo pipefail` for strict error handling
- Comprehensive error checking
- Graceful failure with meaningful messages

### 📚 **Documentation**
- Clear usage instructions
- Function-level documentation
- Input/output specifications

### 🏗️ **Modularity**
- Single responsibility principle
- Configurable through parameters
- Environment-aware (GitHub Actions vs local)

## Usage in Pipelines

### Infrastructure Pipeline
```yaml
- name: Infrastructure Quality Checks
  run: |
    chmod +x ../../.github/scripts/quality-checks.sh
    ../../.github/scripts/quality-checks.sh terraform

- name: Store Infrastructure Outputs
  run: |
    chmod +x ../../.github/scripts/store-infrastructure-outputs.sh
    ../../.github/scripts/store-infrastructure-outputs.sh
```

### Web Pipeline
```yaml
- name: Retrieve Infrastructure Data
  run: |
    chmod +x .github/scripts/retrieve-infrastructure-data.sh
    .github/scripts/retrieve-infrastructure-data.sh

- name: Deploy Application
  run: |
    chmod +x .github/scripts/deploy-application.sh
    .github/scripts/deploy-application.sh
```

## Local Testing

All scripts can be tested locally:

```bash
# Test quality checks
./quality-checks.sh terraform

# Test infrastructure output storage (requires AWS credentials)
./store-infrastructure-outputs.sh ./infra/terraform

# Test infrastructure data retrieval (requires AWS credentials)
./retrieve-infrastructure-data.sh

# Test application deployment (requires environment variables)
export S3_BUCKET="your-bucket"
export CLOUDFRONT_ID="your-distribution-id"
# ... other variables
./deploy-application.sh
```

## Contributing

When adding new scripts:

1. Follow the established patterns and standards
2. Add comprehensive error handling
3. Include usage documentation
4. Test both in GitHub Actions and locally
5. Update this README with new script information