
# AWS CI/CD Assignment - Pipelines with Terraform

This project implements two AWS CI/CD pipelines that automate infrastructure provisioning and application deployment on AWS using Terraform, S3, CloudFront, Lambda, API Gateway, and DynamoDB.

## Project Status

✅ Successfully implemented combined pipeline approach (buildspec-combined.yml)
✅ Eliminated terraform output artifacts issues  
✅ Simplified pipeline management while maintaining all quality gates
✅ All assignment requirements met with enhanced architecture

## Project Structure

```
/
├── infra/                    # Infrastructure code and tests
│   ├── terraform/           # Terraform configuration files  
│   │   ├── main.tf         # Main infrastructure definition
│   │   └── .tflint.hcl     # Terraform linting configuration
│   └── test/               # Terratest unit tests
│       ├── main_test.go    # Infrastructure tests
│       └── go.mod          # Go module definition
├── web/                     # Web application code and tests
│   ├── frontend/           # Static website files
│   │   ├── index.html      # Homepage
│   │   ├── contact.html    # Contact form page
│   │   ├── contact.js      # Contact form functionality
│   │   ├── style.css       # Shared stylesheet
│   │   ├── package.json    # Frontend dependencies
│   │   ├── jest.config.js  # Jest test configuration
│   │   ├── eslint.config.js # ESLint configuration
│   │   ├── vite.config.js  # Vite build configuration
│   │   └── __tests__/      # Frontend tests
│   └── lambda/             # Lambda function code
│       ├── index.js        # Contact form handler
│       ├── index.test.js   # Lambda unit tests
│       ├── package.json    # Lambda dependencies
│       ├── jest.config.js  # Jest configuration
│       └── eslint.config.js # ESLint configuration
├── buildspec-combined.yml   # Combined pipeline (recommended approach)
├── buildspec-infra.yml     # Infrastructure pipeline (legacy/backup)
├── buildspec-web.yml       # Web application pipeline (legacy/backup)
└── README.md               # This file
```

## Architecture

The solution provisions the following AWS resources:

- **S3 Bucket**: Hosts the static website files
- **CloudFront Distribution**: Provides global content delivery and caching
- **API Gateway**: Exposes REST API endpoints for the contact form
- **Lambda Function**: Processes contact form submissions (Node.js)
- **DynamoDB Table**: Stores contact form data with schema:
  - `id` (partition key, UUID)
  - `name` (string)
  - `email` (string) 
  - `message` (string)
  - `created_at` (timestamp)

## Pipelines

### Infrastructure Pipeline (`buildspec-infra.yml`)
- **Trigger**: Commits to `develop` branch
- **Quality Checks**:
  - Terraform formatting (`terraform fmt -check`)
  - Terraform validation (`terraform validate`)
  - Security scanning (`tflint`, `checkov`)
  - Unit testing with Terratest (≥60% coverage)
- **Actions**:
  - Provisions AWS infrastructure with Terraform
  - Outputs resource identifiers for web pipeline

### Web Pipeline (`buildspec-web.yml`)
- **Trigger**: Commits to `develop` branch  
- **Quality Checks**:
  - Frontend: ESLint, Stylelint, Jest tests (≥70% coverage)
  - Lambda: ESLint, Jest tests (≥70% coverage)
- **Actions**:
  - Builds static site with Vite
  - Deploys website to S3
  - Updates Lambda function code
  - Invalidates CloudFront cache

## Setup Instructions

### Prerequisites
- AWS account with appropriate permissions
- AWS CodeBuild projects configured
- Git repository with `develop` branch

### Local Development
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd pipelines-terraform
   ```

2. Install frontend dependencies:
   ```bash
   cd web/frontend
   npm install
   ```

3. Install Lambda dependencies:
   ```bash
   cd ../lambda
   npm install
   ```

4. Install Terratest dependencies:
   ```bash
   cd ../../infra/test
   go mod tidy
   ```

### Pipeline Configuration
1. Create two AWS CodeBuild projects:
   - Infrastructure project using `buildspec-infra.yml`
   - Web project using `buildspec-web.yml`

2. Configure build triggers for the `develop` branch

3. Set up required IAM permissions for CodeBuild service roles

### Testing Locally

#### Frontend Tests
```bash
cd web/frontend
npm test
npm run test:coverage
```

#### Lambda Tests
```bash
cd web/lambda
npm test
npm run test:coverage
```

#### Infrastructure Tests
```bash
cd infra/test
go test -v
```

#### Linting
```bash
# Frontend
cd web/frontend
npm run lint
npm run lint:css

# Lambda
cd web/lambda  
npm run lint

# Infrastructure
cd infra/terraform
terraform fmt -check
terraform validate
tflint
checkov -d .
```

## Demo Steps

1. **Push to develop branch** - Triggers both pipelines automatically
2. **Show pipeline failure** - Introduce linting or test error, push to see failure
3. **Fix and show success** - Correct the issue, push to see successful deployment
4. **Verify infrastructure** - Check AWS Console for provisioned resources
5. **Test website** - Access CloudFront URL and verify site loads
6. **Test contact form** - Submit form and verify data appears in DynamoDB
7. **Verify cache invalidation** - Update site content and see immediate changes

## Outputs

After successful infrastructure deployment:
- **Website URL**: Available via CloudFront distribution
- **API Endpoint**: Contact form API Gateway URL  
- **S3 Bucket**: Website hosting bucket name
- **DynamoDB Table**: Contact submissions table name

## Quality Thresholds

- **Infrastructure Tests**: ≥60% code coverage
- **Frontend Tests**: ≥70% code coverage
- **Lambda Tests**: ≥70% code coverage
- **Linting**: Zero warnings/errors allowed
- **Security**: Checkov security scans must pass

## Troubleshooting

### Common Issues
1. **Pipeline failures**: Check CodeBuild logs for specific error messages
2. **Terraform errors**: Verify AWS permissions and resource limits
3. **Test failures**: Run tests locally to debug before pushing
4. **CORS issues**: Ensure API Gateway CORS is properly configured

### Logs and Monitoring
- CodeBuild execution logs
- Lambda function logs in CloudWatch
- API Gateway execution logs
- CloudFront access logs

---

**Note**: This project is designed for educational purposes as part of an AWS CI/CD assignment. Ensure all AWS resources are properly cleaned up after demonstration to avoid unnecessary costs.