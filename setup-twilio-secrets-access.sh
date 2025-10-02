#!/bin/bash

echo "🔐 Setting up Twilio Secrets Manager access for Lambda..."
echo ""

# Get the Lambda role ARN
LAMBDA_ROLE_ARN=$(aws iam get-role --role-name lambda_role --query 'Role.Arn' --output text)
echo "Lambda Role ARN: $LAMBDA_ROLE_ARN"

# Get current Twilio secret ARN
TWILIO_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id twilio-credentials --region us-west-1 --query 'ARN' --output text)
echo "Twilio Secret ARN: $TWILIO_SECRET_ARN"

# Get Firebase secret ARN (we need this to keep in the policy)
FIREBASE_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id firebaseSDK --region us-west-1 --query 'ARN' --output text)
echo "Firebase Secret ARN: $FIREBASE_SECRET_ARN"

# Get RDS secret ARN
RDS_SECRET_ARN=$(aws rds describe-db-instances --db-instance-identifier my-postgres-db --region us-west-1 --query 'DBInstances[0].MasterUserSecret.SecretArn' --output text)
echo "RDS Secret ARN: $RDS_SECRET_ARN"

echo ""
echo "📝 Step 1: Update Lambda role policy to include Twilio secret..."

# Update the Lambda role's secrets policy to include Twilio
aws iam put-role-policy \
  --role-name lambda_role \
  --policy-name lambda-secrets-policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "secretsmanager:GetSecretValue"
        ],
        "Effect": "Allow",
        "Resource": [
          "'$RDS_SECRET_ARN'",
          "'$FIREBASE_SECRET_ARN'",
          "'$TWILIO_SECRET_ARN'"
        ]
      }
    ]
  }'

if [ $? -eq 0 ]; then
  echo "✅ Lambda role policy updated successfully!"
else
  echo "❌ Failed to update Lambda role policy"
  exit 1
fi

echo ""
echo "�� Step 2: Add resource policy to Twilio secret (allow Lambda to read it)..."

# Add resource policy to Twilio secret
aws secretsmanager put-resource-policy \
  --secret-id twilio-credentials \
  --region us-west-1 \
  --resource-policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowLambdaAccess",
        "Effect": "Allow",
        "Principal": {
          "AWS": "'$LAMBDA_ROLE_ARN'"
        },
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": "*"
      }
    ]
  }'

if [ $? -eq 0 ]; then
  echo "✅ Twilio secret policy updated successfully!"
else
  echo "❌ Failed to update Twilio secret policy"
  exit 1
fi

echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "Your Lambda function can now access the Twilio credentials."
echo ""
echo "🧪 To test, redeploy your Lambda function:"
echo "   cd Backend && npm run build && npm run deploy"
