# /Infra/lambda.tf
# This file defines the Lambda function and its associated resources

# Key components:
# - Lambda function configuration (runtime, memory, timeout)
# - VPC configuration for secure network access
# - Security group rules for network traffic control
# - Environment variables for configuration
# - IAM role and policies for permissions
# - CloudWatch logging configuration
# - Integration with API Gateway
# - Connection to RDS database


# Security group for Lambda function: controls network access for the Lambda function
resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.main_vpc.id  # Associates this security group with our main VPC

  # Allow all outbound traffic from the Lambda function
  # Necessary for the Lambda to communicate with AWS services and external resources
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # allows all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow access to all IP addresses
  }

  tags = merge(local.common_tags, {
    Name = "lambda_sg"
  })
}

# Lambda function: main serverless function that will execute our application code
resource "aws_lambda_function" "my_lambda" {
  # Path to the deployment package (zip file) containing our Lambda function code
  filename         = "${path.module}/../backend/dist/index.zip"
  # Hash of the deployment package to detect changes
  source_code_hash = filebase64sha256("${path.module}/../backend/dist/index.zip")

  function_name    = "hello-lambda"    # Name of the Lambda function in AWS
  role             = aws_iam_role.lambda_role.arn  # IAM role that defines Lambda's permissions
  handler          = "index.handler"   # Entry point for the Lambda function
  runtime          = "nodejs18.x"      # Node.js runtime environment

  # Environment variables for the Lambda function
  environment {
    variables = {
      DB_HOST     = aws_db_instance.postgres.address
      DB_USER     = aws_db_instance.postgres.username
      DB_NAME     = aws_db_instance.postgres.db_name
      RDS_MASTER_SECRET_ARN = aws_db_instance.postgres.master_user_secret[0].secret_arn
    }
  }
  
  # Places the Lambda in our private subnets for secure access to RDS
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Increased memory and timeout for database operations
  memory_size      = 256    # Increased from 128MB to 256MB
  timeout          = 60     # Increased from 30s to 60s
  
  tags = local.common_tags
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.my_lambda.function_name}"
  retention_in_days = 7
  
  tags = local.common_tags
}