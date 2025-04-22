# infra/main.tf

# This file configures the Terraform AWS provider and specifies the required provider version
# It also sets the AWS region for resource creation, using the region defined in the variables.tf file

# Defines the required providers and their version
terraform {
  # Define the provider (AWS) and the version constraint
  required_providers {
    aws = { 
      # hashicorp/aws is the official AWS provider
      source  = "hashicorp/aws"
      
      # Version constraint for the AWS provider
      # Version >= 5.0 but < 6.0 for compatibility
      version = "~> 5.0"
    }
  }
  
  # Define the required Terraform version
  required_version = ">= 1.3.0"
}

# Sets up the AWS provider (interface that lets Terraform interact with AWS resources)
provider "aws" {
  # AWS region where all resources will be created
  # `aws_region` variable is defined in variables.tf
  region = var.aws_region
}