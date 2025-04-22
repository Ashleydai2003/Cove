# infra/variables.tf
# This file defines the input variables that can be used throughout the Terraform configuration

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "us-west-1"
}

# Common tags to be applied to all resources
locals {
  common_tags = {
    Environment          = "production"
    Project             = "CoveApp"
    ManagedBy           = "Terraform"
  }
}