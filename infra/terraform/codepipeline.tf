# AWS CodePipeline for orchestrating infrastructure and web pipelines

# Get current AWS account ID for KMS policy
data "aws_caller_identity" "current" {}

# KMS Key for CodeBuild and CodePipeline encryption (without tags to avoid permission issues)
resource "aws_kms_key" "pipeline_key" {
  description             = "KMS key for CodeBuild and CodePipeline encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-codepipeline"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CodeBuild and CodePipeline"
        Effect = "Allow"
        Principal = {
          Service = [
            "codebuild.amazonaws.com",
            "codepipeline.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })
  # No tags to avoid kms:TagResource permission issues
}

resource "aws_kms_alias" "pipeline_key_alias" {
  name          = "alias/${var.project_name}-${var.deployment_id}-pipeline-key-${random_id.resource_suffix.hex}"
  target_key_id = aws_kms_key.pipeline_key.key_id
}

# Variables needed for CodePipeline
variable "github_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
  # The token will be read from terraform.tfvars or provided via command line
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "Geti0" # Your GitHub username
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "pipelines-terraform" # Your repository name
}

variable "github_branch" {
  description = "GitHub branch to watch"
  type        = string
  default     = "main" # Changed from develop to main
}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project_name}-pipeline-artifacts-${random_id.resource_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-pipeline-artifacts"
    Environment = var.environment
  }
}

# S3 bucket encryption for pipeline artifacts
resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_encryption" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.deployment_id}-codepipeline-role-${random_id.resource_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-${var.deployment_id}-codepipeline-policy-${random_id.resource_suffix.hex}"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = [
          aws_codebuild_project.infrastructure.arn,
          aws_codebuild_project.web.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ],
        Resource = [
          aws_kms_key.pipeline_key.arn
        ]
      }
    ]
  })
}

# IAM role for CodeBuild (Infrastructure)
resource "aws_iam_role" "codebuild_infra_role" {
  name = "${var.project_name}-${var.deployment_id}-codebuild-infra-role-${random_id.resource_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for CodeBuild (Infrastructure)
resource "aws_iam_role_policy" "codebuild_infra_policy" {
  name = "${var.project_name}-${var.deployment_id}-codebuild-infra-policy-${random_id.resource_suffix.hex}"
  role = aws_iam_role.codebuild_infra_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ],
        Resource = "arn:aws:iam::*:role/${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:PutBucketEncryption",
          "s3:GetEncryptionConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketWebsite",
          "s3:GetBucketWebsite"
        ],
        Resource = "arn:aws:s3:::${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission"
        ],
        Resource = "arn:aws:lambda:*:*:function:${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "apigateway:DELETE",
          "apigateway:GET",
          "apigateway:PATCH",
          "apigateway:POST",
          "apigateway:PUT"
        ],
        Resource = [
          "arn:aws:apigateway:*::/restapis",
          "arn:aws:apigateway:*::/restapis/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:TagResource"
        ],
        Resource = "arn:aws:dynamodb:*:*:table/${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:UpdateDistribution",
          "cloudfront:CreateInvalidation",
          "cloudfront:TagResource",
          "cloudfront:CreateResponseHeadersPolicy",
          "cloudfront:DeleteResponseHeadersPolicy",
          "cloudfront:GetResponseHeadersPolicy"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ],
        Resource = [
          aws_kms_key.pipeline_key.arn
        ]
      }
    ]
  })
}

# IAM role for CodeBuild (Web)
resource "aws_iam_role" "codebuild_web_role" {
  name = "${var.project_name}-${var.deployment_id}-codebuild-web-role-${random_id.resource_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for CodeBuild (Web)
resource "aws_iam_role_policy" "codebuild_web_policy" {
  name = "${var.project_name}-${var.deployment_id}-codebuild-web-policy-${random_id.resource_suffix.hex}"
  role = aws_iam_role.codebuild_web_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode"
        ],
        Resource = "arn:aws:lambda:*:*:function:${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ],
        Resource = "arn:aws:cloudfront::*:distribution/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.website.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ],
        Resource = [
          aws_kms_key.pipeline_key.arn
        ]
      }
    ]
  })
}

# CodeBuild project for Infrastructure
resource "aws_codebuild_project" "infrastructure" {
  name          = "${var.project_name}-${var.deployment_id}-infrastructure-${random_id.resource_suffix.hex}"
  description   = "Build project for infrastructure deployment"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild_infra_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VERSION"
      value = "1.5.0"
    }

    environment_variable {
      name  = "GO_VERSION"
      value = "1.19"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-infra.yml"
  }

  # Add CloudWatch Logs configuration
  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.deployment_id}-infrastructure"
      stream_name = random_id.resource_suffix.hex
    }
  }

  # Add encryption configuration using KMS
  encryption_key = aws_kms_key.pipeline_key.arn
}

# CodeBuild project for Web
resource "aws_codebuild_project" "web" {
  name          = "${var.project_name}-${var.deployment_id}-web-${random_id.resource_suffix.hex}"
  description   = "Build project for web application deployment"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild_web_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "NODE_VERSION"
      value = "18"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-web.yml"
  }

  # Add CloudWatch Logs configuration
  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.deployment_id}-web"
      stream_name = random_id.resource_suffix.hex
    }
  }

  # Add encryption configuration using KMS
  encryption_key = aws_kms_key.pipeline_key.arn
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-${var.deployment_id}-pipeline-${random_id.resource_suffix.hex}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.pipeline_key.arn
      type = "KMS"
    }
  }

  # Source Stage - GitHub
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_code"]

      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = var.github_branch
        OAuthToken           = var.github_token
        PollForSourceChanges = "true"
      }
    }
  }

  # Infrastructure Stage
  stage {
    name = "DeployInfrastructure"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_code"]
      output_artifacts = ["infrastructure_artifacts"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.infrastructure.name
      }
    }
  }

  # Web Application Stage
  stage {
    name = "DeployWebApplication"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_code", "infrastructure_artifacts"]
      version         = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.web.name
        PrimarySource = "source_code"
      }
    }
  }
}

# Outputs
output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_url" {
  description = "URL to the pipeline in AWS Console"
  value       = "https://console.aws.amazon.com/codepipeline/home?region=${var.aws_region}#/view/${aws_codepipeline.pipeline.name}"
}
