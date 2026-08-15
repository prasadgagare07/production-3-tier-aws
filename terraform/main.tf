module "networking" {
  source = "./modules/networking"

  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  single_nat_gateway       = var.single_nat_gateway
  tags                     = { Project = var.project_name }
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr
  app_port     = var.app_port
  tags         = { Project = var.project_name }
}

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  tags         = { Project = var.project_name }
}

module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  rds_sg_id             = module.security.rds_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_instance_class     = var.db_instance_class
  multi_az               = var.multi_az
  tags                   = { Project = var.project_name }
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  app_port          = var.app_port
  certificate_arn   = var.certificate_arn
  tags              = { Project = var.project_name }
}

module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  ec2_sg_id              = module.security.ec2_sg_id
  target_group_arn       = module.alb.target_group_arn
  db_host                = module.database.db_endpoint
  db_secret_arn          = module.database.secret_arn
  s3_bucket_name         = module.storage.bucket_name
  s3_bucket_arn          = module.storage.bucket_arn
  aws_region             = var.aws_region
  instance_type          = var.instance_type
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.desired_capacity
  tags                   = { Project = var.project_name }
}

# Route 53 record - only created if domain_name + hosted_zone_id are set.
resource "aws_route53_record" "app" {
  count   = var.domain_name != "" && var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

# --- CloudWatch alarms: only the meaningful ones ---
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more ALB targets are unhealthy"
  dimensions = {
    TargetGroup  = module.alb.target_group_arn
    LoadBalancer = module.alb.alb_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Elevated 5XX error rate from targets"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU sustained above 80%"
  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-postgres"
  }
}
