# security group for Lambda — outbound only (to RDS, SES, Secrets Manager)
resource "aws_security_group" "lambda" {
  name   = "mythirdspace-lambda-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project
  }
}

# security group for RDS — only accepts connections from Lambda on port 5432
resource "aws_security_group" "rds" {
  name   = "mythirdspace-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = {
    Project = var.project
  }
}
