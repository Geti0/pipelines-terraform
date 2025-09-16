# 🚀 AWS CI/CD Pipelines with Terraform

[![Infrastructure Pipeline](https://github.com/Geti0/pipelines-terraform/actions/workflows/infrastructure-pipeline.yml/badge.svg)](https://github.com/Geti0/pipelines-terraform/actions/workflows/infrastructure-pipeline.yml)
[![Web Pipeline](https://github.com/Geti0/pipelines-terraform/actions/workflows/web-pipeline.yml/badge.svg)](https://github.com/Geti0/pipelines-terraform/actions/workflows/web-pipeline.yml)

A production-ready AWS CI/CD implementation using **separate pipelines** with **Parameter Store integration** for seamless data sharing.

---

## 🏗️ **Architecture Overview**

### **Pipeline Flow**
```
📋 Code Push → 🏗️ Infrastructure Pipeline → 📊 Parameter Store → 🌐 Web Pipeline
```

### **Infrastructure Pipeline**
- **Triggers**: Changes to `infra/` directory
- **Actions**: Deploy AWS infrastructure via Terraform
- **Outputs**: Store infrastructure details in Parameter Store
- **Resources**: S3, CloudFront, API Gateway, Lambda, DynamoDB

### **Web Pipeline** 
- **Triggers**: Automatically after Infrastructure Pipeline success
- **Actions**: Deploy web application and Lambda function
- **Inputs**: Read infrastructure details from Parameter Store
- **Deployment**: Frontend to S3, Lambda function update

---

## 🛠️ **Technology Stack**

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Infrastructure** | Terraform | AWS resource provisioning |
| **CI/CD** | GitHub Actions | Pipeline automation |
| **Data Sharing** | AWS Parameter Store | Inter-pipeline communication |
| **Frontend** | Vite + HTML/CSS/JS | Static web application |
| **Backend** | AWS Lambda + Node.js | Serverless contact form |
| **Database** | DynamoDB | Contact form submissions |
| **CDN** | CloudFront | Global content delivery |
| **Storage** | S3 | Static website hosting |

---

## 📁 **Project Structure**

```
pipelines-terraform/
├── 🔧 cicd/workflows/           # GitHub Actions pipelines
│   ├── infrastructure-pipeline.yml  # Terraform deployment
│   └── web-pipeline.yml            # Web app deployment
├── 🏗️ infra/                       # Infrastructure as Code
│   ├── terraform/                  # Terraform configurations
│   │   ├── main.tf                # Main infrastructure config
│   │   ├── terraform.tfvars       # Environment variables
│   │   └── ...                    # Additional Terraform files
│   └── test/                      # Infrastructure tests
├── 🌐 web/                         # Web application
│   ├── frontend/                  # Static web frontend
│   │   ├── index.html            # Main page
│   │   ├── contact.html          # Contact form
│   │   ├── style.css             # Styling
│   │   └── contact.js            # Frontend logic
│   └── lambda/                    # Serverless backend
│       ├── index.js              # Lambda function
│       └── package.json          # Lambda dependencies
└── 📚 Documentation/               # Project documentation
    ├── IAM_POLICY_LIMIT_RESOLUTION.md
    ├── LAMBDA_CONFLICT_RESOLUTION.md
    ├── PARAMETER_STORE_SETUP.md
    └── PIPELINE_DEPENDENCY_CHAIN.md
```

---

## 🚀 **Quick Start**

### **Prerequisites**
- AWS Account with appropriate permissions
- GitHub repository with Actions enabled
- AWS CLI configured locally

### **Setup Steps**

1. **Clone Repository**
   ```bash
   git clone https://github.com/Geti0/pipelines-terraform.git
   cd pipelines-terraform
   ```

2. **Configure AWS Credentials**
   - Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to GitHub Secrets
   - Ensure IAM user has required permissions (see documentation)

3. **Update Terraform Variables**
   ```bash
   cd infra/terraform
   # Edit terraform.tfvars with your specific values
   ```

4. **Deploy Infrastructure**
   ```bash
   # Push changes to trigger infrastructure pipeline
   git add infra/
   git commit -m "Deploy infrastructure"
   git push origin main
   ```

5. **Deploy Web Application**
   - Web pipeline automatically triggers after infrastructure completion
   - Or manually trigger: `git add web/` and push

---

## 🔄 **Pipeline Features**

### **🛡️ Resilience & Error Handling**
- **Lambda Conflict Resolution**: Automatic retry logic for ResourceConflictException
- **Quality Gate Flexibility**: Continue-on-error for non-critical checks
- **IAM Management**: Automated policy creation with manual attachment support
- **State Management**: Robust Terraform state handling

### **📊 Quality Assurance**
- **Frontend**: ESLint, Jest testing, coverage reporting
- **Backend**: Lambda function testing, Node.js best practices
- **Infrastructure**: TFLint, Checkov security scanning, Terratest validation
- **Deployment**: Automated testing and validation

### **🔗 Advanced Features**
- **Pipeline Dependencies**: Automatic web pipeline triggering
- **Parameter Store Integration**: Seamless data sharing between pipelines
- **Multi-environment Support**: Development and production configurations
- **Monitoring**: CloudWatch integration and error tracking

---

## 📋 **Manual Operations**

### **IAM Policy Attachment**
Due to AWS policy limits (10 policies per user), Parameter Store policy requires manual attachment:

```bash
# Find the created policy
aws iam list-policies --scope Local --query "Policies[?contains(PolicyName, 'parameter-store')]"

# Attach to your IAM user
aws iam attach-user-policy --user-name YOUR_USER --policy-arn POLICY_ARN
```

### **Parameter Store Verification**
```bash
# List stored parameters
aws ssm describe-parameters --region eu-north-1

# Read specific parameter
aws ssm get-parameter --name "/pipelines-terraform/s3-bucket-name" --region eu-north-1
```

---

## 🎯 **AWS Resources Deployed**

| Service | Resource | Purpose |
|---------|----------|---------|
| **S3** | Website Bucket | Static website hosting |
| **CloudFront** | Distribution | CDN and HTTPS termination |
| **API Gateway** | REST API | Contact form endpoint |
| **Lambda** | Contact Function | Form submission processing |
| **DynamoDB** | Submissions Table | Contact form data storage |
| **IAM** | Policies & Roles | Security and permissions |
| **Parameter Store** | Configuration | Pipeline data sharing |

---

## 🔍 **Troubleshooting**

### **Common Issues**
- **Lambda ResourceConflictException**: See `LAMBDA_CONFLICT_RESOLUTION.md`
- **IAM Policy Limits**: See `IAM_POLICY_LIMIT_RESOLUTION.md`
- **Parameter Store Access**: See `PARAMETER_STORE_SETUP.md`

### **Pipeline Monitoring**
- **GitHub Actions**: Monitor workflow execution in GitHub
- **AWS CloudWatch**: Monitor Lambda function logs
- **Parameter Store**: Verify infrastructure data sharing

---

## 📚 **Documentation**

| Document | Purpose |
|----------|---------|
| `IAM_POLICY_LIMIT_RESOLUTION.md` | Solving AWS IAM policy limits |
| `LAMBDA_CONFLICT_RESOLUTION.md` | Handling Lambda update conflicts |
| `PARAMETER_STORE_SETUP.md` | Parameter Store configuration |
| `PARAMETER_STORE_SUCCESS.md` | Implementation success record |
| `PIPELINE_DEPENDENCY_CHAIN.md` | Pipeline architecture details |

---

## 🎉 **Project Status**

- ✅ **Separate Pipelines**: Infrastructure and Web pipelines operating independently
- ✅ **Parameter Store Integration**: Seamless data sharing between pipelines
- ✅ **Error Handling**: Robust error recovery and retry mechanisms
- ✅ **Quality Gates**: Comprehensive testing and validation
- ✅ **Production Ready**: Scalable and maintainable architecture

---

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the pipeline system
5. Submit a pull request

---

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ using AWS, Terraform, and GitHub Actions**
