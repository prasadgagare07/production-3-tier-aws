output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Point your browser here to test the app over HTTP before DNS/HTTPS is set up"
}

output "app_url" {
  value = var.domain_name != "" ? "https://${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

output "vpc_id" { value = module.networking.vpc_id }
output "db_endpoint" { value = module.database.db_endpoint }
output "s3_bucket_name" { value = module.storage.bucket_name }
output "asg_name" { value = module.compute.asg_name }
