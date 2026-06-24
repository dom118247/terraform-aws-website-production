terraform {
    required_version = ">=1.15.0" #  locks Terraform itself - stops someone (or CI) running an older Terraform binary against the code. Terraform has breaking changes between versions — this prevents silent breakage if someone on a team has an older version installed.
    required_providers {        # locks the AWS provider - The AWS provider is a plugin Terraform downloads separately. It's what knows how to talk to AWS APIs — without it, none of the aws_ resources exist. The version pin (~> 5.0) means "5.x only, never 6" — protects from a major version upgrade silently breaking things.
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
    region = "us-east-1"
}