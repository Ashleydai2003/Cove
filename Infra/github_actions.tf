#
# github_actions.tf
#
# IAM resources for GitHub Actions CI/CD
# Defines OIDC provider and IAM role for secure, credential-less deployments
#
# Key components:
# - OIDC Identity Provider for GitHub Actions
# - IAM Role with trust policy for GitHub repository
# - IAM Policy with permissions for Lambda deployment, EC2 management, SSM, etc.
# - Policy attachment linking role and policy
#
# Security Features:
# - No long-lived AWS credentials stored in GitHub
# - Temporary credentials via OIDC
# - Scoped to specific repository and branches
# - Least privilege permissions

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# OIDC Identity Provider for GitHub Actions
# Allows GitHub Actions to assume IAM roles without storing credentials
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's OIDC thumbprint (valid as of 2023)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(local.common_tags, {
    Name        = "github-actions-oidc"
    Description = "OIDC provider for GitHub Actions CI/CD"
  })
}

# IAM Role for GitHub Actions
# This role is assumed by GitHub Actions workflows to deploy to AWS
resource "aws_iam_role" "github_actions" {
  name        = "GithubActionsRole"
  description = "IAM role for GitHub Actions CI/CD workflows"

  # Trust policy allowing GitHub Actions to assume this role
  # Only allows specific repository and branches
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:StanfordCS194/spr25-team-23:ref:refs/heads/main",
              "repo:StanfordCS194/spr25-team-23:ref:refs/heads/develop"
            ]
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "github-actions-role"
    Description = "Role for GitHub Actions CI/CD"
  })
}

# IAM Policy for GitHub Actions
# Defines what actions the GitHub Actions role can perform
resource "aws_iam_policy" "github_actions" {
  name        = "GithubActionsPolicy"
  description = "Permissions for GitHub Actions CI/CD workflows"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2 Instance Management (for migrations)
      {
        Sid    = "StartStopDescribeInstance"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.migration_instance.id}"
      },
      {
        Sid    = "DescribeInstancesForWaiter"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },

      # SSM Access (for running migration commands)
      {
        Sid    = "SSMCommandAccess"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMDocumentAccess"
        Effect = "Allow"
        Action = [
          "ssm:DescribeDocumentParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
      },

      # Secrets Manager (for retrieving RDS credentials during migrations)
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "${aws_db_instance.postgres.master_user_secret[0].secret_arn}*"
      },

      # Lambda Deployment (for both main API and batch matcher)
      {
        Sid    = "LambdaDeploymentAccess"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration",
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.my_lambda.arn,
          aws_lambda_function.batch_matcher.arn
        ]
      },

      # CloudWatch Logs (for viewing logs in workflows)
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.my_lambda.function_name}:*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.batch_matcher.function_name}:*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "github-actions-policy"
    Description = "Policy for GitHub Actions CI/CD"
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# Outputs for reference
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role (use this in GitHub Secrets as AWS_ROLE_ARN)"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_policy_arn" {
  description = "ARN of the GitHub Actions IAM policy"
  value       = aws_iam_policy.github_actions.arn
}

