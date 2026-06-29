terraform {
    required_version = ">= 1.15.0, < 2.0.0" # locks Terraform itself — stops CI running an older or incompatible binary
    required_providers {        # locks the AWS provider — version pin (~> 6) means "6.x only, never 7" — protects from a major version upgrade silently breaking things.
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6"
        }
    }
}

provider "aws" { # what connects Terraform to AWS — it's the configuration for the plugin that was declared in required_provider
    region = var.aws_region
}

provider "aws" {
    alias  = "us_east_1"
    region = "us-east-1" # ACM + WAF — CloudFront requirement
}

provider "aws" {
    alias  = "eu_west_1"
    region = "eu-west-1" # S3 state bucket replica — different region for disaster recovery
}