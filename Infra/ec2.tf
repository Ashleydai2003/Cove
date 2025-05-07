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

  # Optional: allow outbound to RDS via its SG (or skip if using full egress above)
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
  }

  tags = merge(local.common_tags, {
    Name = "migration-sg"
  })
}

# IAM Role for EC2 instance to access Secrets Manager and SSM
resource "aws_iam_role" "migration_role" {
  name = "migration-role"

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

# Grant read access to DB credentials in Secrets Manager
resource "aws_iam_policy" "migration_secrets" {
  name        = "migration-secrets-access"
  description = "Allow access to RDS secrets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["secretsmanager:GetSecretValue"],
      Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
    }]
  })

  tags = local.common_tags
}

# Attach Secrets Manager policy to role
resource "aws_iam_role_policy_attachment" "migration_secrets" {
  role       = aws_iam_role.migration_role.name
  policy_arn = aws_iam_policy.migration_secrets.arn
}

# Enable SSM Session Manager for shell access (no SSH needed)
resource "aws_iam_role_policy_attachment" "migration_ssm" {
  role       = aws_iam_role.migration_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile binding role to EC2
resource "aws_iam_instance_profile" "migration" {
  name = "migration-profile"
  role = aws_iam_role.migration_role.name
}

# EC2 instance for running Prisma migrations manually
resource "aws_instance" "migration" {
  ami                    = "ami-04fc83311a8d478df"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.migration_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.migration.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git nodejs npm postgresql15

              # Optional: preload environment vars for convenience
              cat << 'EOENV' > /etc/profile.d/migration-env.sh
              export DB_HOST="${aws_db_instance.postgres.address}"
              export DB_NAME="${aws_db_instance.postgres.db_name}"
              export DB_USER="${aws_db_instance.postgres.username}"
              export RDS_SECRET_ARN="${aws_db_instance.postgres.master_user_secret[0].secret_arn}"
              EOENV
              EOF

  tags = merge(local.common_tags, {
    Name = "migration-instance"
  })
}
