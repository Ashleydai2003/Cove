# /Infra/vpce.tf
# This file defines the VPC endpoints and their security groups

# Key Features:
# - Creates VPC endpoints for secure AWS service access within VPC
# - Configures security group to control endpoint access
# - Enables private DNS resolution for endpoints
# - Deploys endpoints into private subnets for enhanced security
# - Allows Lambda functions to access AWS services without internet gateway

# Security group for VPC endpoints
resource "aws_security_group" "vpce_sg" {
  name        = "vpce-sg"
  description = "Allow Lambda SG access"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow inbound HTTPS (443) traffic from Lambda security group
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [
      aws_security_group.lambda_sg.id,
      aws_security_group.migration_sg.id  # Add EC2 migration security group
    ]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "vpce-sg"
  })
}

# VPC Endpoint for Secrets Manager
# This endpoint allows the Lambda function to access Secrets Manager without going through the public internet
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"  # Secrets Manager service endpoint
  vpc_endpoint_type = "Interface"  # Interface endpoint type for private connectivity
  subnet_ids        = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]  # Place in private subnets
  security_group_ids = [aws_security_group.vpce_sg.id]  # Use VPC endpoint security group

  private_dns_enabled = true  # Enable private DNS for the endpoint

  tags = merge(local.common_tags, {
    Name = "secretsmanager-endpoint"
  })
}

# VPC Endpoint for S3
# This endpoint allows the Lambda function to access S3 without going through the public internet
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(local.common_tags, {
    Name = "s3-endpoint"
  })
} 