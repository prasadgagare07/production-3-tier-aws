variable "project_name" { type = string }
variable "private_db_subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_allocated_storage" {
  type    = number
  default = 20
}
variable "multi_az" {
  type        = bool
  default     = false
  description = "COST NOTE: true doubles RDS cost. false = single-AZ (fine for a learning project)."
}
variable "backup_retention_days" {
  type    = number
  default = 1
}
variable "tags" {
  type    = map(string)
  default = {}
}
