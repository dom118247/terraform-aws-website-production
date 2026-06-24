# tells tf where to store its state file (in s3)

terraform {
    backend "s3" {
        bucket         = "mythirdspace-state-prod"
        key            = "production/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
        use_lockfile   = true 
    }
}