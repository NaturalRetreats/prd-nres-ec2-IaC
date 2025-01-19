# prd-nres-ec2-IaC
This repo contains terraform code to deploy production EC2 instance for the RDS backend prd-nres-oradb. This will also create 8443, 7443 target groups and listeners. This code will attach the listeners to the target groups. The load balancer is already created in the VPC via [text](https://github.com/NaturalRetreats/prd-nres-rds-IaC)

The EC2 instances are part of autoscaling group. The autoscaling group is part of the load balancer target group. Minimim instance count is 2 and maximum is 4. Refer to the main.tf file for more details on the criteria for scaling up and down.

## Prerequisites

- Terraform
- AWS CLI
- AWS IAM user with access to the AWS resources
- AMI ID for the EC2 instance
- Security Group ID for the EC2 instance
- Key Pair Name for the EC2 instance
- Subnet ID for the EC2 instance
- VPC ID for the EC2 instance

## Usage

1. Clone the repository
2. Navigate to the directory
3. Run `terraform init`
4. Run `terraform plan`
5. Run `terraform apply`

## Variables

- `aws_access_key`: AWS access key
- `aws_secret_key`: AWS secret key

## Outputs

- `instance_id`: ID of the EC2 instance
- `public_ip`: Public IP address of the EC2 instance
- `private_ip`: Private IP address of the EC2 instance

## Notes

- The EC2 instance will be created in the specified VPC, subnet, and security group.
- The EC2 instance will be created with the specified AMI.
- The EC2 instance will be created with the specified key pair.
- The EC2 instance will be created with the specified user data.

## Terraform.tfvars

- aws_access_key: AWS access key
- aws_secret_key: AWS secret key

