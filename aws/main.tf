terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.11.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

data "aws_caller_identity" "current" {}