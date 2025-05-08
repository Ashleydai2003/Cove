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
