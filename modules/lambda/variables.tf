variable "project" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "db_instance_address" {
  type = string
}

variable "db_instance_name" {
  type = string
}

variable "db_instance_username" {
  type = string
}

variable "domain_name" {
  type = string
}
