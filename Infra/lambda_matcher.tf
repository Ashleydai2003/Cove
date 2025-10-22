#
# lambda_matcher.tf
#
# Lambda function for batch matcher worker
# Integrates with existing VPC, RDS, and security infrastructure
#
# Key components:
# - Lambda function with VPC access and Secrets Manager integration
# - IAM role with permissions for RDS, Secrets Manager, DLQ, and X-Ray
# - Security group allowing RDS access and Secrets Manager endpoint access
# - Dead Letter Queue (SQS) for failed invocations
# - CloudWatch Logs for monitoring and debugging
# - EventBridge schedule (defined in eventbridge.tf)
#
# Security Architecture:
# 1. Lambda runs in private subnets (no internet access)
# 2. Database password retrieved from AWS Secrets Manager (not hardcoded)
# 3. Access to RDS via VPC security group (port 5432)
# 4. Access to Secrets Manager via VPC endpoint (port 443)
# 5. Reserved concurrency = 1 (prevents overlapping runs)
# 6. Advisory lock in PostgreSQL (extra safety against concurrent runs)
#
# Network Flow:
# Lambda (private subnet) → VPC Endpoint → Secrets Manager (get DB password)
# Lambda (private subnet) → RDS (private subnet) → PostgreSQL (port 5432)
#

# Lambda function for batch matcher
resource "aws_lambda_function" "batch_matcher" {
  function_name = "cove-batch-matcher"
  role          = aws_iam_role.batch_matcher_lambda_role.arn
  
  # Deployment package (built separately)
  filename         = "${path.module}/../Backend/dist/matcher.zip"
  source_code_hash = filebase64sha256("${path.module}/../Backend/dist/matcher.zip")
  
  handler = "matcherLambda.handler"
  runtime = "nodejs18.x"
  
  # Timeout: 5 minutes (matcher can take a while with many users)
  timeout = 300
  
  # Memory: 1024 MB (matcher needs memory for scoring calculations)
  memory_size = 1024
  
  # Reserved concurrency: 1 (only one matcher can run at a time)
  reserved_concurrent_executions = 1
  
  # Environment variables - use Secrets Manager for RDS credentials
  # Note: AWS_REGION is automatically set by Lambda runtime, don't include it here
  environment {
    variables = {
      NODE_ENV               = "production"
      RDS_MASTER_SECRET_ARN  = aws_db_instance.postgres.master_user_secret[0].secret_arn
      DB_USER                = aws_db_instance.postgres.username
      DB_HOST                = aws_db_instance.postgres.address
      DB_NAME                = aws_db_instance.postgres.db_name
    }
  }
  
  # VPC config - use existing private subnets and security group
  vpc_config {
    subnet_ids         = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id
    ]
    security_group_ids = [aws_security_group.lambda_matcher_sg.id]
  }
  
  # Dead letter queue for failed invocations
  dead_letter_config {
    target_arn = aws_sqs_queue.batch_matcher_dlq.arn
  }
  
  # Enable tracing for debugging
  tracing_config {
    mode = "Active"
  }
  
  tags = merge(local.common_tags, {
    Name    = "cove-batch-matcher"
    Purpose = "Scheduled matching worker"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.batch_matcher_basic,
    aws_iam_role_policy_attachment.batch_matcher_vpc,
    aws_cloudwatch_log_group.batch_matcher_logs
  ]
}

# IAM role for batch matcher Lambda
resource "aws_iam_role" "batch_matcher_lambda_role" {
  name = "cove-batch-matcher-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-lambda-role"
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "batch_matcher_basic" {
  role       = aws_iam_role.batch_matcher_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy (if using VPC)
resource "aws_iam_role_policy_attachment" "batch_matcher_vpc" {
  role       = aws_iam_role.batch_matcher_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom policy for DLQ access
resource "aws_iam_role_policy" "batch_matcher_dlq" {
  name = "cove-batch-matcher-dlq-policy"
  role = aws_iam_role.batch_matcher_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.batch_matcher_dlq.arn
      }
    ]
  })
}

# Custom policy for X-Ray tracing
resource "aws_iam_role_policy" "batch_matcher_xray" {
  name = "cove-batch-matcher-xray-policy"
  role = aws_iam_role.batch_matcher_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom policy for Secrets Manager access (RDS credentials)
resource "aws_iam_role_policy" "batch_matcher_secrets" {
  name = "cove-batch-matcher-secrets-policy"
  role = aws_iam_role.batch_matcher_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
      }
    ]
  })
}

# Security group for Lambda (to access RDS)
resource "aws_security_group" "lambda_matcher_sg" {
  name        = "cove-lambda-matcher-sg"
  description = "Security group for batch matcher Lambda - allows RDS access"
  vpc_id      = aws_vpc.main_vpc.id
  
  # Outbound to RDS (port 5432)
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
    description     = "PostgreSQL access to RDS"
  }
  
  # Outbound to internet via NAT for npm packages, etc (HTTPS only)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for dependencies"
  }
  
  tags = merge(local.common_tags, {
    Name = "cove-lambda-matcher-sg"
  })
}

# Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "batch_matcher_dlq" {
  name                      = "cove-batch-matcher-dlq"
  message_retention_seconds = 1209600 # 14 days
  
  # Enable encryption at rest
  sqs_managed_sse_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-dlq"
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "batch_matcher_logs" {
  name              = "/aws/lambda/cove-batch-matcher"
  retention_in_days = 14
  
  # Enable encryption
  kms_key_id = null  # Use default AWS encryption
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-logs"
  })
}

# Outputs
output "batch_matcher_lambda_arn" {
  description = "ARN of the batch matcher Lambda function"
  value       = aws_lambda_function.batch_matcher.arn
}

output "batch_matcher_lambda_name" {
  description = "Name of the batch matcher Lambda function"
  value       = aws_lambda_function.batch_matcher.function_name
}

output "batch_matcher_dlq_url" {
  description = "URL of the batch matcher DLQ"
  value       = aws_sqs_queue.batch_matcher_dlq.url
}

