terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "blueshift_artifacts" {
  bucket = "blueshift-artifacts-199836513795"

  tags = {
    Name        = "BlueShift Artifacts"
    Environment = "Dev"
    Project     = "BlueShift"
    ManagedBy   = "Terraform"
  }
}
