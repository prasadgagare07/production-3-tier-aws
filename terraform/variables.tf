variable "project_name" {
  type    = string
  default = "cloud-project-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

# REPLACE with your target AWS region, e.g. "us-east-1" or "ap-south-1"
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.20.0/24", "10.20.21.0/24"]
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "multi_az" {
  type    = bool
  default = false
}

# REPLACE with an ACM certificate ARN once you have a domain + Route 53
# hosted zone. Leave "" to deploy HTTP-only first (recommended for the
# first deploy so you can verify the app before adding DNS/HTTPS).
variable "certificate_arn" {
  type    = string
  default = ""
}

# REPLACE with your registered domain name, or leave "" to skip Route 53.
variable "domain_name" {
  type    = string
  default = ""
}

# REPLACE with your existing Route 53 hosted zone ID (if domain_name is set).
variable "hosted_zone_id" {
  type    = string
  default = ""
}
