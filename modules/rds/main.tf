module "rds" {
    source  = "terraform-aws-modules/rds/aws"
    version = "~> 6.0"

    identifier = "mythirdspace-db"

    engine            = "postgres"
    engine_version    = "16"
    instance_class    = "db.t3.small"
    allocated_storage = 20

    db_name  = "mythirdspace"
    username = "dbadmin"
    port     = 5432

    manage_master_user_password = true # AWS generates and stores password in Secrets Manager

    vpc_security_group_ids = var.vpc_security_group_ids

    maintenance_window = "Mon:00:00-Mon:03:00"
    backup_window      = "03:00-06:00"

    create_db_subnet_group = true
    subnet_ids             = var.subnet_ids

    family               = "postgres16"
    major_engine_version = "16"

    storage_encrypted   = true
    deletion_protection = true

    tags = {
        Project = var.project
    }
}
