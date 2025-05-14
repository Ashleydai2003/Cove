# Infra/secrets.tf
# This file sets up the secrets manager and defines secrets for db credentials and Firebase

# Key components:
# - Grants lambda access to firebase admin

# Reference the existing Firebase credentials secret
data "aws_secretsmanager_secret" "firebase_credentials" {
  name = "firebaseSDK"
}

# Grant Lambda access to the Firebase secret
resource "aws_secretsmanager_secret_policy" "firebase_secret_policy" {
  secret_arn = data.aws_secretsmanager_secret.firebase_credentials.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_role.arn
        }
        Resource = data.aws_secretsmanager_secret.firebase_credentials.arn
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