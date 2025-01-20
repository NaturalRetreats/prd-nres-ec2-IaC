variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "key_pair" {
  description = "Key pair name"
  type        = string
  default     = "prd-nres-ec2-key-pair" # create a key pair in the region
}

variable "ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-0339ce5ee4f5eb7fa" # get the ami after creating the clone of the existing instance
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "Oracle Migration and Modernization to AWS RDS"
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "hdesai@parkar.digital"
    Owner       = "Parkar Team"
    CreatedBy   = "hdesai@parkar.digital"
    CreatedOn   = "January 2025"
  }
}
