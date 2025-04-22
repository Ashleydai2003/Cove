# /Infra/api_gateway.tf
# This file configures the API Gateway service which acts as the entry point for HTTP requests

# Key components:
# - API Gateway configuration (HTTP API type)
# - Integration with Lambda function
# - Route configuration for handling requests
# - Stage deployment settings
# - Custom domain and SSL certificate integration
# - Logging configuration for monitoring and debugging

# The API Gateway:
# 1. Receives incoming HTTP requests
# 2. Routes them to the appropriate Lambda function
# 3. Returns the Lambda's response to the client
# 4. Handles authentication, logging, and SSL termination

# Fetch certificate from ACM
data "aws_acm_certificate" "api_certificate" {
  domain      = "api.coveapp.co"  # The domain name of your certificate
  statuses    = ["ISSUED"]        # Only fetch issued certificates
  most_recent = true              # Get the most recent certificate if multiple exist
}

resource "aws_apigatewayv2_api" "api" {
  name          = "my-api"
  protocol_type = "HTTP"
  
  tags = local.common_tags
}

# Tells API Gateway what service it should call when a request comes in: Lambda function
resource "aws_apigatewayv2_integration" "api_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY" # API Gateway will forward the full HTTP request to Lambda in a special format.
  integration_uri    = aws_lambda_function.my_lambda.invoke_arn #ARN of the Lambda function.
  integration_method = "POST" # refers to how API Gateway will call Lambda, not what the client uses
}

# Routes define how API Gateway should handle incoming requests
# Tells API_gateway which integration to use for different HTTP methods and paths
resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"  # This creates a catch-all route for any HTTP method and path
  target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

# Stages represent different deployment environments (prod, dev, test, etc.)
# Allows multiple versions of our API to run simultaneously
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"  # or "dev", "test", etc.
  auto_deploy = true    # Automatically deploy changes to the stage
  
  # Set up logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseTime  = "$context.responseLatency"
      integrationError = "$context.integration.error"
    })
  }
  
  tags = local.common_tags
}

# Grants API Gateway permission to invoke Lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Custom domain name for our API
# Also allow you to use HTTPS with your own certificate
resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = "api.coveapp.co" 

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.api_certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  
  tags = local.common_tags
}

# Maps custom domain to API stage
# Without this mapping, custom domain won't be connected to the API
resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.api_stage.id
}

# Logging is essential for monitoring, debugging, and auditing your API
# It helps you understand how your API is being used and troubleshoot issues
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/my-api"
  retention_in_days = 7
  
  tags = local.common_tags
}