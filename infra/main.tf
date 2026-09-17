terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # State separado del de TaxOps prod: la organización tiene su propio ciclo de
  # vida. Reutiliza el backend de state existente de la cuenta.
  backend "s3" {
    bucket         = "awsorg-tfstate-786567028012"
    key            = "organization/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "awsorg-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Scope     = "aws-organization"
    }
  }
}

data "aws_organizations_organization" "current" {}
