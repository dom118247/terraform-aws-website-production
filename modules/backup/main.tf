# backup vault — where AWS Backup stores the backups
resource "aws_backup_vault" "website" {
  name = "mythirdspace-backup-vault"

  tags = {
    Project = var.project
  }
}

# backup plan — defines when and how long to keep backups
resource "aws_backup_plan" "website" {
  name = "mythirdspace-backup-plan"

  rule {
    rule_name         = "daily-backups"
    target_vault_name = aws_backup_vault.website.name
    schedule          = "cron(0 3 * * ? *)" # run at 3am daily

    lifecycle {
      delete_after = 7 # keep backups for 7 days
    }
  }

  tags = {
    Project = var.project
  }
}

# IAM role — gives AWS Backup permission to back up RDS
resource "aws_iam_role" "backup" {
  name = "mythirdspace-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = var.project
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# backup selection — tells AWS Backup which resources to back up
resource "aws_backup_selection" "rds" {
  name         = "mythirdspace-rds-backup"
  plan_id      = aws_backup_plan.website.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [var.rds_instance_arn] # backs up the RDS instance
}

# S3 cross-region replication for state bucket
# replication requires versioning — already enabled on mythirdspace-state-prod

# replica bucket in eu-west-1 (Ireland) — different region from eu-west-2 (London)
resource "aws_s3_bucket" "state_replica" {
  provider = aws.eu_west_1
  bucket   = "mythirdspace-state-replica"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = var.project
    Purpose = "state-bucket-replica"
  }
}

resource "aws_s3_bucket_versioning" "state_replica" {
  provider = aws.eu_west_1
  bucket   = aws_s3_bucket.state_replica.id

  versioning_configuration {
    status = "Enabled" # required for replication target
  }
}
