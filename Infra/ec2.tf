# Security group for the EC2 instance that runs manual migrations
resource "aws_security_group" "migration_sg" {
  name        = "migration-sg"
  description = "Security group for manual migration EC2 instance"
  vpc_id      = aws_vpc.main_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "migration-sg"
  })
}

# Security group for the Socket.io server
resource "aws_security_group" "socket_sg" {
  name        = "socket-sg"
  description = "Security group for Socket.io server"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow inbound traffic on Socket.io port
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere for Socket.io connections
  }

  # Allow inbound traffic on health check port
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow health checks
  }

  # Allow SSH access for debugging (optional - can be removed in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this to your IP in production
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "socket-sg"
  })
}

# IAM role for Socket.io server
resource "aws_iam_role" "socket_role" {
  name = "socket-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# Enable SSM Session Manager for shell access (no SSH needed)
resource "aws_iam_role_policy_attachment" "migration_ssm" {
  role       = aws_iam_role.migration_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Enable SSM Session Manager for Socket.io server
resource "aws_iam_role_policy_attachment" "socket_ssm" {
  role       = aws_iam_role.socket_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile binding role to EC2
resource "aws_iam_instance_profile" "migration" {
  name = "migration-profile"
  role = aws_iam_role.migration_role.name
}

# Instance profile for Socket.io server
resource "aws_iam_instance_profile" "socket" {
  name = "socket-profile"
  role = aws_iam_role.socket_role.name
}

# Grant read access to DB credentials in Secrets Manager for Socket.io server
resource "aws_iam_policy" "socket_secrets" {
  name        = "socket-secrets-access"
  description = "Allow Socket.io server access to RDS and Firebase secrets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = [
          aws_db_instance.postgres.master_user_secret[0].secret_arn,
          data.aws_secretsmanager_secret.firebase_credentials.arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Attach Secrets Manager policy to Socket.io role
resource "aws_iam_role_policy_attachment" "socket_secrets" {
  role       = aws_iam_role.socket_role.name
  policy_arn = aws_iam_policy.socket_secrets.arn
}

# Policy for database access - allows Socket.io server to interact with PostgreSQL RDS
resource "aws_iam_role_policy" "socket_db_policy" {
  name = "socket-db-policy"
  role = aws_iam_role.socket_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # RDS management permissions
        Action = [
          "rds:DescribeDBInstances",  # Allows reading RDS instance details
          "rds:DescribeDBSnapshots",  # Needed for backup/restore operations if required
          "rds:ModifyDBInstance",     # Allow modifying RDS instance if needed
          "rds:DescribeDBParameters", # Allow viewing DB parameters
          "rds:ModifyDBParameterGroup" # Allow modifying DB parameters if needed
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:${aws_db_instance.postgres.identifier}"
      }
    ]
  })
}

# Policy for CloudWatch Logs: allows the Socket.io server to write logs to CloudWatch
resource "aws_iam_role_policy" "socket_logs_policy" {
  name = "socket-logs-policy"
  role = aws_iam_role.socket_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",    # Allows creating a new log group if it doesn't exist
          "logs:CreateLogStream",   # Allows creating new log streams within the log group
          "logs:PutLogEvents",      # Allows writing log events to the stream
          "logs:DescribeLogGroups", # Allows listing log groups
          "logs:DescribeLogStreams" # Allows listing log streams
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/socket-server:*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/socket:*"
        ]
      }
    ]
  })
}

# EC2 instance for running Prisma migrations manually
resource "aws_instance" "migration" {
  ami                    = "ami-04fc83311a8d478df"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.migration_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.migration.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git nodejs npm postgresql15

              # Optional: preload environment vars for convenience
              echo 'export DB_HOST=${aws_db_instance.postgres.address}' >> /etc/profile
              echo 'export DB_NAME=${aws_db_instance.postgres.db_name}' >> /etc/profile
              echo 'export DB_USER=${aws_db_instance.postgres.username}' >> /etc/profile
              echo 'export RDS_MASTER_SECRET_ARN=${aws_db_instance.postgres.master_user_secret[0].secret_arn}' >> /etc/profile
              source /etc/profile
              EOF

  tags = merge(local.common_tags, {
    Name = "migration-instance"
  })
}

# EC2 instance for Socket.io server
resource "aws_instance" "socket_server" {
  ami                    = "ami-04fc83311a8d478df"  # Amazon Linux 2023
  instance_type          = "t3.small"               # 2 vCPU, 2 GB RAM
  subnet_id              = aws_subnet.public_subnet_1.id  # Public subnet for Socket.io access
  vpc_security_group_ids = [aws_security_group.socket_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.socket.name
  # Using SSM instead of SSH key for secure access

  user_data = <<-EOF
              #!/bin/bash
              # Set GitHub token from Terraform variable (base64 decode if provided)
              if [ -n "${var.github_token}" ]; then
                export GITHUB_TOKEN="${var.github_token}"
                echo "GitHub token set for private repository access"
              else
                echo "No GitHub token provided"
              fi
              
              yum update -y
              yum install -y git nodejs npm postgresql15 docker

              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Start Docker service
              systemctl start docker
              systemctl enable docker

              # Add ec2-user to docker group and fix permissions
              usermod -a -G docker ec2-user
              chmod 666 /var/run/docker.sock

              # Create app directory
              mkdir -p /opt/cove-socket
              cd /opt/cove-socket

              # Clone your repository with GitHub token
              if [ -n "$GITHUB_TOKEN" ]; then
                echo "Cloning private repository with GitHub token..."
                git clone https://$GITHUB_TOKEN@github.com/Ashleydai2003/Cove.git . || {
                  echo "Failed to clone with token"
                  exit 1
                }
              else
                echo "No GitHub token provided, attempting public clone..."
                git clone https://github.com/Ashleydai2003/Cove.git . || {
                  echo "Failed to clone repository. Repository may be private."
                  echo "Please ensure GITHUB_TOKEN is set and redeploy."
                  exit 1
                }
              fi

              # Set environment variables
              cat > /opt/cove-socket/.env << 'ENVEOF'
              NODE_ENV=production
              RDS_MASTER_SECRET_ARN=${aws_db_instance.postgres.master_user_secret[0].secret_arn}
              DB_USER=${aws_db_instance.postgres.username}
              DB_HOST=${aws_db_instance.postgres.address}
              DB_NAME=${aws_db_instance.postgres.db_name}
              FIREBASE_PROJECT_ID=cove-40d9f
              SOCKET_PORT=3001
              ENVEOF

              # Build and run Docker container with restart policy
              cd /opt/cove-socket/Backend
              
              # Check if source code exists
              if [ ! -f "package.json" ]; then
                echo "ERROR: Source code not found. Git clone may have failed."
                echo "Contents of /opt/cove-socket:"
                ls -la /opt/cove-socket
                exit 1
              fi
              
              # Install dependencies
              npm install
              
              # Build Docker image
              docker build -f Dockerfile.socket -t socket-server . || {
                echo "Failed to build Docker image"
                echo "Docker build logs:"
                docker build -f Dockerfile.socket -t socket-server . --progress=plain
                exit 1
              }
              
              # Stop and remove existing container if it exists
              docker stop socket-server 2>/dev/null || true
              docker rm socket-server 2>/dev/null || true
              
              # Run with restart policy for production reliability
              docker run -d \
                --restart=always \
                -p 3001:3001 \
                --name socket-server \
                --env-file /opt/cove-socket/.env \
                socket-server || {
                echo "Failed to start Docker container"
                exit 1
              }
              
              # Wait for container to start and check health
              sleep 10
              if ! curl -f http://localhost:3001/health > /dev/null 2>&1; then
                echo "Health check failed"
                docker logs socket-server
                exit 1
              fi

              # Set up log rotation for Docker logs
              cat > /etc/logrotate.d/docker-socket << 'LOGROTATEEOF'
              /var/lib/docker/containers/*/socket-server-json.log {
                  daily
                  missingok
                  rotate 7
                  compress
                  notifempty
                  create 644 root root
              }
              LOGROTATEEOF

              # Create a systemd service for additional reliability
              cat > /etc/systemd/system/socket-server.service << 'SERVICEEOF'
              [Unit]
              Description=Cove Socket.io Server
              Requires=docker.service
              After=docker.service

              [Service]
              Type=oneshot
              RemainAfterExit=yes
              ExecStart=/usr/bin/docker run -d --restart=always -p 3001:3001 --name socket-server --env-file /opt/cove-socket/.env socket-server
              ExecStop=/usr/bin/docker stop socket-server
              ExecStopPost=/usr/bin/docker rm socket-server

              [Install]
              WantedBy=multi-user.target
              SERVICEEOF

              # Enable and start the service
              systemctl daemon-reload
              systemctl enable socket-server.service
              systemctl start socket-server.service

              # Health check script
              cat > /opt/cove-socket/health-check.sh << 'HEALTHEOF'
              #!/bin/bash
              if curl -f http://localhost:3001/health > /dev/null 2>&1; then
                  echo "Socket server is healthy"
                  exit 0
              else
                  echo "Socket server is not responding"
                  exit 1
              fi
              HEALTHEOF
              chmod +x /opt/cove-socket/health-check.sh

              # Set up CloudWatch monitoring
              yum install -y amazon-cloudwatch-agent
              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
              {
                  "agent": {
                      "metrics_collection_interval": 60,
                      "run_as_user": "root"
                  },
                  "logs": {
                      "logs_collected": {
                          "files": {
                              "collect_list": [
                                  {
                                      "file_path": "/var/lib/docker/containers/*/socket-server-json.log",
                                      "log_group_name": "/aws/ec2/socket-server",
                                      "log_stream_name": "{instance_id}",
                                      "timezone": "UTC"
                                  }
                              ]
                          }
                      }
                  },
                  "metrics": {
                      "metrics_collected": {
                          "disk": {
                              "measurement": ["used_percent"],
                              "metrics_collection_interval": 60,
                              "resources": ["*"]
                          },
                          "mem": {
                              "measurement": ["mem_used_percent"],
                              "metrics_collection_interval": 60
                          }
                      }
                  }
              }
              CWEOF

              # Start CloudWatch agent
              systemctl start amazon-cloudwatch-agent
              systemctl enable amazon-cloudwatch-agent
              EOF

  tags = merge(local.common_tags, {
    Name = "socket-server"
  })
}

# Elastic IP for Socket.io server (optional - for static IP)
resource "aws_eip" "socket_server" {
  instance = aws_instance.socket_server.id
  domain   = "vpc"
  
  tags = merge(local.common_tags, {
    Name = "socket-server-eip"
  })
}
