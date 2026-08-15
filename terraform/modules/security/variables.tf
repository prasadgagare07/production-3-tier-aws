variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "app_port" {
  type    = number
  default = 8080
}
variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to reach EC2 via SSM/bastion path. Kept for reference; direct SSH is disabled by default (SSM Session Manager used instead)."
  default     = "127.0.0.1/32"
}
variable "tags" {
  type    = map(string)
  default = {}
}
