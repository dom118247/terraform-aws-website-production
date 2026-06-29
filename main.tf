# looks up existing Route53 hosted zone by domain name
data "aws_route53_zone" "website" {
  name         = var.domain_name
  private_zone = false
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
}

module "waf" {
  source  = "./modules/waf"
  project = var.project

  providers = {
    aws = aws.us_east_1
  }
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project                        = var.project
  domain_name                    = var.domain_name
  www_domain_name                = var.www_domain_name
  s3_bucket_id                   = module.s3.bucket_id
  s3_bucket_arn                  = module.s3.bucket_arn
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  zone_id                        = data.aws_route53_zone.website.zone_id
  waf_web_acl_arn                = module.waf.web_acl_arn

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "dns" {
  source = "./modules/dns"

  project                             = var.project
  domain_name                         = var.domain_name
  www_domain_name                     = var.www_domain_name
  zone_id                             = data.aws_route53_zone.website.zone_id
  cloudfront_distribution_domain_name = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id           = module.cloudfront.hosted_zone_id
}

module "vpc" {
  source  = "./modules/vpc"
  project = var.project
}

module "security_groups" {
  source  = "./modules/security-groups"
  project = var.project
  vpc_id  = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"

  project                = var.project
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.security_groups.rds_sg_id]
}

module "ses" {
  source = "./modules/ses"

  project     = var.project
  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.website.zone_id
}

module "lambda" {
  source = "./modules/lambda"

  project              = var.project
  aws_region           = var.aws_region
  subnet_ids           = module.vpc.private_subnets
  lambda_sg_id         = module.security_groups.lambda_sg_id
  db_secret_arn        = module.rds.db_instance_master_user_secret_arn
  db_instance_address  = module.rds.db_instance_address
  db_instance_name     = module.rds.db_instance_name
  db_instance_username = module.rds.db_instance_username
  domain_name          = var.domain_name
}

module "api_gateway" {
  source = "./modules/api-gateway"

  project              = var.project
  domain_name          = var.domain_name
  www_domain_name      = var.www_domain_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}

module "monitoring" {
  source = "./modules/monitoring"

  project                    = var.project
  cloudfront_distribution_id = module.cloudfront.distribution_id
  lambda_function_name       = module.lambda.function_name
  rds_instance_identifier    = module.rds.db_instance_identifier
}

module "backup" {
  source = "./modules/backup"

  project          = var.project
  rds_instance_arn = module.rds.db_instance_arn

  providers = {
    aws           = aws
    aws.eu_west_1 = aws.eu_west_1
  }
}
