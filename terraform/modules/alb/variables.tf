variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_port" { type = number }
variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS. Leave empty to deploy HTTP-only (e.g. before a domain is ready)."
  default     = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
