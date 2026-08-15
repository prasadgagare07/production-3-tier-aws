# Production-Style 3-Tier AWS Cloud Project

A production-style 3-tier web application deployed on AWS using Terraform and GitHub Actions.

## Architecture

Internet
   ↓
Route 53 (Optional)
   ↓
Application Load Balancer
   ↓
EC2 Auto Scaling Group
   ↓
RDS PostgreSQL

Additional services:
- S3
- Secrets Manager
- CloudWatch
- Systems Manager
- IAM
- NAT Gateway

## Project Structure

```text
production-3-tier-aws/
│
├── app/
│   ├── server.js
│   ├── db.js
│   ├── logger.js
│   ├── package.json
│   ├── .env.example
│   └── public/
│       └── index.html
│
├── terraform/
│   ├── providers.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── main.tf
│   ├── terraform.tfvars.example
│   │
│   └── modules/
│       ├── networking/
│       ├── security/
│       ├── compute/
│       ├── alb/
│       ├── database/
│       └── storage/
│
├── scripts/
│   ├── user_data.sh.tpl
│   └── deploy.sh
│
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       └── deploy.yml
│
├── tests/
│   └── smoke.test.js
│
├── .gitignore
└── README.md
Technology Stack
AWS
Terraform
Node.js
Express
PostgreSQL
Amazon EC2
Application Load Balancer
Auto Scaling
Amazon RDS
Amazon S3
AWS Secrets Manager
CloudWatch
Systems Manager
IAM
GitHub Actions
GitHub OIDC
AWS Architecture
Networking
One VPC
Two Availability Zones
Public subnets
Private application subnets
Private database subnets
Internet Gateway
NAT Gateway
Route Tables
Security Groups
Compute
EC2 instances in private subnets
Auto Scaling Group
Minimum 2 instances
Application Load Balancer
Health checks
Database
Amazon RDS PostgreSQL
Private subnet
No public access
Accessible only from EC2 security group
Storage
Private S3 bucket
Server-side encryption
Versioning enabled
Public access blocked
Security
No SSH access
Systems Manager Session Manager
IAM roles
Secrets Manager
Least-privilege security groups
IMDSv2
Deployment
Infrastructure is created using Terraform.
cd terraform

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
Application deployment is handled through GitHub Actions.
GitHub
   ↓
GitHub Actions
   ↓
AWS OIDC
   ↓
S3
   ↓
AWS Systems Manager
   ↓
EC2 Auto Scaling Group
CI/CD
Two GitHub Actions workflows are included:
terraform.yml
Handles:
Terraform validation
Terraform plan
Terraform apply
deploy.yml
Handles:
Application testing
Application packaging
Upload to S3
Deployment to EC2
Health check
Monitoring
CloudWatch is used for:
EC2 monitoring
Application logs
ALB monitoring
RDS monitoring
CloudWatch alarms
Security Flow
Internet
   ↓
ALB
   ↓
EC2
   ↓
RDS

S3 ← EC2
Secrets Manager ← EC2
CloudWatch ← EC2 / ALB / RDS
The database is never publicly accessible.
Skills Demonstrated
AWS Cloud Architecture
VPC Networking
EC2
Auto Scaling
ALB
RDS
S3
IAM
Secrets Manager
CloudWatch
Systems Manager
Terraform
Infrastructure as Code
GitHub Actions
CI/CD
OIDC
Security
Troubleshooting
High Availability
Cost Awareness
Project Goal
Build and deploy a realistic production-style AWS environment while demonstrating practical Cloud Engineer skills in infrastructure, automation, security, monitoring, deployment, and troubleshooting.
