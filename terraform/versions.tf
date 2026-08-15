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

  # Remote state - RECOMMENDED for real use. Create the bucket/table once
  # (outside Terraform, or with a bootstrap script) then uncomment.
  # backend "s3" {
  #   bucket         = "REPLACE_WITH_YOUR_TFSTATE_BUCKET"
  #   key            = "project-1/terraform.tfstate"
  #   region         = "REPLACE_WITH_AWS_REGION"
  #   dynamodb_table = "REPLACE_WITH_LOCK_TABLE"
  #   encrypt        = true
  # }
}
