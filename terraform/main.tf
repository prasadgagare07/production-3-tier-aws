terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  azs                     = var.azs
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs = var.private_db_subnet_cidrs
  single_nat_gateway      = var.single_nat_gateway
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr
  app_port     = var.app_port
}

module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  rds_sg_id             = module.security.rds_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_instance_class     = var.db_instance_class
  multi_az              = var.multi_az
  backup_retention_days = var.backup_retention_days
}

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  app_port          = var.app_port
  certificate_arn   = var.certificate_arn
}

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  ec2_sg_id             = module.security.ec2_sg_id
  target_group_arn      = module.alb.target_group_arn

  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  s3_bucket_name = module.storage.bucket_name
  s3_bucket_arn  = module.storage.bucket_arn

  db_host       = module.database.db_endpoint
  db_secret_arn = module.database.secret_arn

  aws_region = var.aws_region
}
