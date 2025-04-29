# Infra/secrets.tf
# This file sets up the secrets manager and defines secrets for db credentials

# Key components:
# - Eventually firebase creds

# Using RDS's built-in Secrets Manager integration to manage the database password
# The password is stored securely and accessed by the Lambda function

# Firebase service account credentials
resource "aws_secretsmanager_secret" "firebase_credentials" {
  name        = "firebase-service-account"
  description = "Firebase service account credentials for backend authentication"
  
  tags = local.common_tags
}

# Grant Lambda access to the Firebase secret
resource "aws_secretsmanager_secret_policy" "firebase_secret_policy" {
  secret_arn = aws_secretsmanager_secret.firebase_credentials.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_role.arn
        }
        Resource = "*"
      }
    ]
  })
}

# TODO: Add Firebase secret ARN to Lambda environment variables
# This needs to be added to the aws_lambda_function resource in lambda.tf
# Example:
# environment {
#   variables = {
#     FIREBASE_SECRET_ARN = aws_secretsmanager_secret.firebase_credentials.arn
#   }
# }