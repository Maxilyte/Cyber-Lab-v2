terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "cyber-lab-v2-tfstate-689546299913"
    key          = "terraform.tfstate"
    region       = "ca-central-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cyber-lab-v2-vpc"
  }
}
