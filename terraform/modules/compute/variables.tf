variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "private_app_subnet_ids" { type = list(string) }
variable "ec2_sg_id" { type = string }
variable "target_group_arn" { type = string }
variable "db_host" { type = string }
variable "db_secret_arn" { type = string }
variable "s3_bucket_name" { type = string }
variable "s3_bucket_arn" { type = string }
variable "aws_region" { type = string }
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
variable "tags" {
  type    = map(string)
  default = {}
}
