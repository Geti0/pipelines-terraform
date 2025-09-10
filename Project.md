# AWS CI/CD Pipelines with Terraform - Project Presentation

## 🎯 Project Overview

This project demonstrates a complete **AWS CI/CD pipeline implementation** using modern DevOps practices. We've built an automated system that deploys a contact form web application with infrastructure provisioning, quality checks, and continuous deployment.

### What We Built
- **Two separate CI/CD pipelines** for infrastructure and web application
- **Automated quality gates** with testing and security scanning
- **Modern web application** with contact form functionality
- **Full AWS cloud infrastructure** using Infrastructure as Code

---

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   Git Repository │
│   Push Code     │───▶│   (develop)     │
└─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  AWS CodeBuild  │
                       │  Two Pipelines  │
                       └─────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
        ┌─────────────────────┐    ┌─────────────────────┐
        │ Infrastructure      │    │ Web Application     │
        │ Pipeline            │    │ Pipeline            │
        │                     │    │                     │
        │ • Terraform Checks  │    │ • Frontend Tests    │
        │ • Security Scans    │    │ • Lambda Tests      │
        │ • Deploy AWS        │    │ • Build & Deploy    │
        └─────────────────────┘    └─────────────────────┘
                    │                       │
                    └───────────┬───────────┘
                                ▼
                    ┌─────────────────────┐
                    │   AWS Services      │
                    │ • S3 (Website)      │
                    │ • CloudFront (CDN)  │
                    │ • Lambda (API)      │
                    │ • API Gateway       │
                    │ • DynamoDB (Data)   │
                    └─────────────────────┘
```

---

## 🔄 The Complete Flow

### 1. **Developer Workflow**
```
Developer writes code → Commits to 'develop' branch → Pushes to repository
```

### 2. **Automated Pipeline Trigger**
- Both pipelines start **automatically** when code is pushed to `develop` branch
- Pipelines run **in parallel** for faster deployment

### 3. **Quality Gates (What Makes Our Pipelines Smart)**

#### Infrastructure Pipeline Quality Checks:
- ✅ **Terraform Format Check** - Ensures code is properly formatted
- ✅ **Terraform Validation** - Validates infrastructure syntax
- ✅ **Security Scanning** - Scans for security vulnerabilities
- ✅ **Unit Testing** - Tests infrastructure code (≥60% coverage required)

#### Web Pipeline Quality Checks:
- ✅ **ESLint** - JavaScript code quality checks
- ✅ **Stylelint** - CSS code quality checks  
- ✅ **Unit Tests** - Frontend and Lambda tests (≥70% coverage required)
- ✅ **Build Validation** - Ensures the application builds successfully

### 4. **Deployment Process**
If all quality checks pass:
1. **Infrastructure** gets provisioned/updated in AWS
2. **Web application** gets built and deployed
3. **CloudFront cache** gets invalidated for instant updates

---

## 🛠️ Technical Implementation

### **Pipeline 1: Infrastructure (buildspec-infra.yml)**
```yaml
Key Features:
- Terraform 1.5.0 for Infrastructure as Code
- Go 1.19 for testing framework (Terratest)
- Security tools: TFLint + Checkov
- Automated AWS resource provisioning
```

**What it does:**
1. **Installs** required tools (Terraform, TFLint, Checkov)
2. **Validates** Terraform code format and syntax
3. **Scans** for security vulnerabilities
4. **Tests** infrastructure with Go-based tests
5. **Deploys** AWS resources automatically

### **Pipeline 2: Web Application (buildspec-web.yml)**
```yaml
Key Features:
- Node.js 18 runtime
- Modern build tools (Vite, Jest, ESLint)
- Frontend and Lambda testing
- Automated deployment to AWS
```

**What it does:**
1. **Installs** Node.js dependencies
2. **Lints** JavaScript and CSS code
3. **Tests** both frontend and backend code
4. **Builds** the web application
5. **Deploys** to S3 and updates Lambda function
6. **Invalidates** CloudFront cache

---

## ☁️ AWS Infrastructure Components

### **Frontend Hosting**
- **S3 Bucket**: Stores website files (HTML, CSS, JS)
- **CloudFront**: Global CDN for fast content delivery
- **Security**: HTTPS enforced, security headers applied

### **Backend API**
- **API Gateway**: RESTful API endpoint for contact form
- **Lambda Function**: Processes form submissions (Node.js)
- **DynamoDB**: NoSQL database stores contact submissions

### **Security & Monitoring**
- **IAM Roles**: Least privilege access for all services
- **Encryption**: S3 and DynamoDB encrypted at rest
- **X-Ray Tracing**: Performance monitoring enabled
- **CORS**: Properly configured for cross-origin requests

---

## 📊 Quality Standards & Metrics

### **Code Coverage Requirements**
- Infrastructure Tests: **≥60%** coverage
- Frontend Tests: **≥70%** coverage  
- Lambda Tests: **≥70%** coverage

### **Quality Gates**
- **Zero warnings/errors** allowed in linting
- **All security scans** must pass
- **All unit tests** must pass
- **Build process** must complete successfully

### **Failure Handling**
- Pipeline **stops immediately** if any check fails
- **Clear error messages** help developers fix issues
- **No deployment** happens with failing quality gates

---

## 🌐 Application Features

### **Frontend (Static Website)**
- **Modern HTML5** structure
- **Responsive CSS** design
- **Contact form** with client-side validation
- **Vite build system** for optimized production builds

### **Backend (Lambda Function)**
- **Input validation** (email format, required fields)
- **Error handling** with proper HTTP status codes
- **CORS support** for browser compatibility
- **UUID generation** for unique submission IDs
- **DynamoDB integration** with proper error handling

### **Data Storage**
```json
Contact Submission Format:
{
  "id": "uuid-here",
  "name": "John Doe", 
  "email": "john@example.com",
  "message": "Hello world",
  "created_at": "2025-09-10T10:30:00Z"
}
```

---

## 🚀 Demonstration Flow

### **1. Show Current State**
- Visit the live website via CloudFront URL
- Show AWS resources in console
- Demonstrate contact form functionality

### **2. Make a Code Change**
- Modify frontend styling or add a feature
- Commit and push to `develop` branch

### **3. Watch Pipelines Execute**
- Show both pipelines starting automatically
- Monitor quality checks in real-time
- Explain what each stage is doing

### **4. Show Quality Gates in Action**
- Introduce a deliberate error (linting issue)
- Show how pipeline fails and prevents deployment
- Fix the error and show successful deployment

### **5. Verify Deployment**
- Check updated website via CloudFront
- Submit test contact form
- Verify data in DynamoDB table

---

## 📈 Key Benefits & Best Practices

### **Automation Benefits**
- **Reduced Manual Work**: No manual deployments needed
- **Consistency**: Same process every time
- **Speed**: Parallel pipelines = faster delivery
- **Reliability**: Quality gates prevent bad deployments

### **Security Best Practices**
- **Infrastructure as Code**: All resources version controlled
- **Security Scanning**: Automated vulnerability detection
- **Least Privilege**: IAM roles with minimal permissions
- **Encryption**: Data encrypted in transit and at rest

### **DevOps Best Practices**
- **Separation of Concerns**: Infrastructure and application pipelines separate
- **Testing**: Comprehensive test coverage requirements
- **Monitoring**: X-Ray tracing for performance insights
- **Rollback Capability**: Infrastructure state managed by Terraform

---

## 💡 Real-World Applications

This pattern is used by companies like:
- **Netflix**: For microservice deployments
- **Amazon**: For internal service delivery
- **Spotify**: For feature rollouts
- **Uber**: For infrastructure management

### **Scalability**
- Can handle **multiple environments** (dev, staging, prod)
- Supports **multiple applications** with same pattern
- Enables **team autonomy** with guardrails
- Facilitates **compliance** with automated checks

---

## 📚 Technologies Demonstrated

### **Infrastructure as Code**
- Terraform (AWS resources)
- Terratest (Infrastructure testing)
- TFLint (Terraform linting)
- Checkov (Security scanning)

### **CI/CD & DevOps**
- AWS CodeBuild (Pipeline execution)
- Git-based workflows
- Automated quality gates
- Infrastructure and application separation

### **Frontend Development**
- Modern HTML5/CSS3
- Vite (Build tool)
- Jest (Testing framework)
- ESLint (Code quality)

### **Backend Development**
- Node.js Lambda functions
- AWS SDK integration
- REST API design
- NoSQL database operations

### **Cloud Services**
- S3 (Static hosting)
- CloudFront (CDN)
- API Gateway (REST APIs)
- Lambda (Serverless compute)
- DynamoDB (NoSQL database)
- IAM (Security)

---

## 🎉 Project Outcomes

✅ **Fully Automated CI/CD Pipeline**
✅ **Infrastructure as Code Implementation** 
✅ **Quality Gates and Testing**
✅ **Security Best Practices**
✅ **Scalable Architecture**
✅ **Production-Ready Application**

This project demonstrates modern DevOps practices and cloud-native development, showing how to build reliable, automated, and secure deployment pipelines that can scale for enterprise use.
