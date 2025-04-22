# /Infra/iam.tf
# This file defines IAM roles and policies for our AWS resources

# Key components:
# - IAM roles for service access control
# - Trust policies defining who can assume roles
# - Permission policies specifying allowed actions
# - Resource-based policies for cross-service access
# - Policy attachments linking roles and policies
# - Managed policy usage for common permissions
# - Custom policy definitions for specific needs
# - Least privilege principle implementation


# IAM role for Lambda execution: defines what AWS services the Lambda function can access
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"  # Allows Lambda service to temporarily assume this role
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
  
  tags = local.common_tags
}

# Policy for Secrets Manager access allows Lambda to retrieve database credentials from Secrets Manager
resource "aws_iam_role_policy" "lambda_secrets_policy" {
  name = "lambda-secrets-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = [
          aws_db_instance.postgres.master_user_secret[0].secret_arn
        ]
      }
    ]
  })
}

# Policy for database access - allows Lambda to interact with our PostgreSQL RDS instance
resource "aws_iam_role_policy" "lambda_db_policy" {
  name = "lambda-db-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # RDS management permissions
        Action = [
          "rds:DescribeDBInstances",  # Allows reading RDS instance details
          "rds:DescribeDBSnapshots"   # Needed for backup/restore operations if required
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:${aws_db_instance.postgres.identifier}"
      }
    ]
  })
}

# Policy for VPC access: allows Lambda to create and manage ENIs in the VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy for CloudWatch Logs: allows the Lambda function to write logs to CloudWatch
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "lambda-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",    # Allows creating a new log group if it doesn't exist
          "logs:CreateLogStream",   # Allows creating new log streams within the log group
          "logs:PutLogEvents"       # Allows writing log events to the stream
        ]
        Effect   = "Allow"
        # Restricts access to only the log group for this specific Lambda function
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.my_lambda.function_name}:*"
      }
    ]
  })
}

# Retrieves the current AWS account ID for use in constructing ARNs
data "aws_caller_identity" "current" {}
