# Infra/secrets.tf
# This file sets up the secrets manager and defines secrets for db credentials, Firebase, and Twilio

# Key components:
# - Grants lambda access to Firebase admin
# - Grants lambda access to Twilio credentials

# Reference the existing Firebase credentials secret
data "aws_secretsmanager_secret" "firebase_credentials" {
  name = "firebaseSDK"
}

# Reference the Twilio credentials secret
data "aws_secretsmanager_secret" "twilio_credentials" {
  name = "twilio-credentials"
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

# Grant Lambda access to the Twilio secret
resource "aws_secretsmanager_secret_policy" "twilio_secret_policy" {
  secret_arn = data.aws_secretsmanager_secret.twilio_credentials.arn
  
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
        Resource = data.aws_secretsmanager_secret.twilio_credentials.arn
      }
    ]
  })
}