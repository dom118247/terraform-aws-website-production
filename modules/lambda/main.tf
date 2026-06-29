# IAM role — gives Lambda permission to run and access other AWS services
resource "aws_iam_role" "lambda" {
  name = "mythirdspace-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = var.project
  }
}

# attach AWS managed policy — allows Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# custom policy — allows Lambda to send emails via SES and read DB password from Secrets Manager
resource "aws_iam_role_policy" "lambda" {
  name = "mythirdspace-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "sesv2:SendEmail"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# the Lambda function itself
resource "aws_lambda_function" "signup" {
  function_name = "mythirdspace-signup"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "handler.lambda_handler" # filename.function_name

  filename         = "${path.root}/lambda/signup.zip"   # zipped Python code
  source_code_hash = filebase64sha256("${path.root}/lambda/signup.zip")

  timeout     = 30
  memory_size = 128

  # Lambda runs inside the VPC so it can reach RDS in private subnets
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  # environment variables — passed to the Python function at runtime
  environment {
    variables = {
      DB_HOST         = var.db_instance_address
      DB_NAME         = var.db_instance_name
      DB_USER         = var.db_instance_username
      DB_SECRET_ARN   = var.db_secret_arn
      SES_FROM        = "hello@${var.domain_name}"
      AWS_REGION_NAME = var.aws_region
    }
  }

  tags = {
    Project = var.project
  }
}
