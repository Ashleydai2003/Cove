# /Infra/rds.tf
# This file defines the RDS PostgreSQL database instance

# Key components:
# - RDS instance configuration (engine, size, storage)
# - Security group for database access control
# - Subnet group for VPC placement
# - Secrets Manager integration for credentials
# - Backup and maintenance settings
# - Monitoring and logging configuration
# - High availability options
# - Network security and encryption

# Define the security group for our RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow inbound traffic on port 5432 (PostgreSQL) from Lambda and EC2 migration instance"
  vpc_id      = aws_vpc.main_vpc.id
  
  # Inbound rules: Allow access from Lambda security group, EC2 migration instance, and Socket.io server on port 5432
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [
      aws_security_group.lambda_sg.id,      # Allow access from Lambda security group
      aws_security_group.migration_sg.id,   # Allow access from EC2 migration instance
      aws_security_group.socket_sg.id       # Allow access from Socket.io server
    ]
  }

  # Outbound rules: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All traffic
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to the security group name and description
      name,
      description,
    ]
  }
  
  tags = merge(local.common_tags, {
    Name = "rds_sg"
  })
}

resource "aws_db_subnet_group" "main_db_subnet" {
  name       = "main-db-subnet-group"
  description = "Subnet group for RDS instances"  # Descriptive label for the group
  subnet_ids  = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
  tags = merge(local.common_tags, {
    Name = "main-db-subnet-group"
  })
}


# Define the RDS PostgreSQL database instance
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20       # Size of the storage in GB (can change later)
  instance_class    = "db.t3.micro"  # Instance size (small for dev can change)
  engine               = "postgres"  # Database engine
  engine_version       = "17.4"     # PostgreSQL version
  identifier           = "my-postgres-db"  # Database instance name
  db_name              = "covedb"    # Database name
  port                 = 5432      # Default PostgreSQL port
  multi_az             = true     # Enable Multi-AZ for high availability
  publicly_accessible  = false     # Ensure the DB is not publicly accessible
  storage_encrypted    = true      # Enable encryption at rest
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Attach the security group

  # Subnet group to place the database in the private subnet
  db_subnet_group_name = aws_db_subnet_group.main_db_subnet.id

  # username (password will be managed by Secrets Manager)
  username = "mydbuser"
  
  # Enable RDS to manage the master user password using Secrets Manager
  manage_master_user_password = true

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"  # UTC time
  maintenance_window     = "Mon:04:00-Mon:05:00"  # UTC time

  tags = merge(local.common_tags, {
    Name = "my-postgres-db"
  })
}