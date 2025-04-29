# Infra/vpc.tf
# This file sets up the Virtual Private Cloud (VPC) which will be used to isolate our Lambda functions 
# and RDS instances in private subnets

# Key components:
# - VPC: Isolates our cloud resources in a private network
# - Public Subnets: Host NAT Gateways for internet access
# - Private Subnets: Secure location for Lambda and RDS
# - Internet Gateway: Enables internet access for public subnets
# - NAT Gateway: Allows private resources to access internet
# - Route Tables: Control traffic flow between subnets
# - Security Groups: Network firewall rules for resources
# - VPC Endpoints: Private access to AWS services


# Define our vpc resource 
# main_vpc is the identifier Terraform uses to refer to this specific VPC within our configuration
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"  # Defines the IP range for the VPC
  enable_dns_support = true     # Allows DNS resolution within the VPC
  enable_dns_hostnames = true   # Allows EC2 instances to have DNS hostnames
  tags = merge(local.common_tags, {
    Name = "main_vpc"
  })
}

# Create public subnet 1 for NAT Gateway
# Public subnets are necessary to host the NAT Gateway, which allows private resources
# (like our Lambda function) to access the internet while remaining secure
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-1b"
  map_public_ip_on_launch = true  # Automatically assign public IPs to resources launched here
  tags = merge(local.common_tags, {
    Name = "public_subnet_1"
  })
}

# Create public subnet 2 for NAT Gateway
# A second public subnet provides redundancy in case of AZ failure
# This follows AWS best practices for high availability
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-1c"
  map_public_ip_on_launch = true  # Automatically assign public IPs to resources launched here
  tags = merge(local.common_tags, {
    Name = "public_subnet_2"
  })
}

# Create private subnet 1 for secure communication (no public access)
# Private subnets are where we place resources that shouldn't be directly accessible from the internet
# Our Lambda function and RDS instance will be placed here for enhanced security
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id   # Link subnet to our VPC
  cidr_block        = "10.0.1.0/24"     # Defines the IP range for our first private subne
  availability_zone = "us-west-1b"      # The availability zone to deploy to
  map_public_ip_on_launch = false       # Ensure that no public IP is assigned to instances
  tags = merge(local.common_tags, {
    Name = "private_subnet_1"
  })
}

# Create private subnet 2 for secure communication (no public access)
# A second private subnet provides redundancy and high availability
# Resources can be distributed across AZs to prevent single point of failure
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id   # Link subnet to our VPC
  cidr_block        = "10.0.2.0/24"     # Defines the IP range for our second private subnet
  availability_zone = "us-west-1c"      # The availability zone to deploy to
  map_public_ip_on_launch = false       # Ensure that no public IP is assigned to instances
  tags = merge(local.common_tags, {
    Name = "private_subnet_2"
  })
}

# Internet Gateway for public internet access
# This allows resources in public subnets to access the internet
# It's a required component for the NAT Gateway to function
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge(local.common_tags, {
    Name = "main_igw"
  })
}

# Elastic IP for NAT Gateway
# NAT Gateway requires a static IP address that won't change
# This ensures consistent outbound connectivity for our Lambda function
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(local.common_tags, {
    Name = "nat_eip"
  })
}

# NAT Gateway for private subnet internet access
# This critical component allows resources in private subnets (like our Lambda)
# to access the internet while remaining secure and not directly accessible
# It's placed in a public subnet and uses the Elastic IP
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id  # Must be in a public subnet
  tags = merge(local.common_tags, {
    Name = "main_nat"
  })
  depends_on = [aws_internet_gateway.main]  # Ensure IGW exists before creating NAT
}

# Route table for public subnets
# This routes traffic from public subnets to the Internet Gateway
# Allows the NAT Gateway to access the internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # All internet traffic
    gateway_id = aws_internet_gateway.main.id  # Route through Internet Gateway
  }

  tags = merge(local.common_tags, {
    Name = "public_rt"
  })
}

# Route table for private subnets
# This routes traffic from private subnets through the NAT Gateway
# Allows our Lambda function to access the internet while remaining secure
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # All internet traffic
    nat_gateway_id = aws_nat_gateway.main.id  # Route through NAT Gateway
  }

  tags = merge(local.common_tags, {
    Name = "private_rt"
  })
}

# Associate public subnets with public route table
# This ensures resources in public subnets can access the internet
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
# This ensures resources in private subnets (Lambda, RDS) route through NAT Gateway
# for internet access while remaining secure
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private.id
}