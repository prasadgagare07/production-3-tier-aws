variable "project_name" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" {
  type        = list(string)
  description = "Availability zones to spread subnets across (2 recommended for HA + cost balance)"
}
variable "public_subnet_cidrs" { type = list(string) }
variable "private_app_subnet_cidrs" { type = list(string) }
variable "private_db_subnet_cidrs" { type = list(string) }
variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "true = 1 NAT Gateway (cheaper, single point of failure). false = 1 per AZ (HA, costs more)."
}
variable "tags" {
  type    = map(string)
  default = {}
}
