# CloudWatch alarm — triggers if CloudFront error rate exceeds 5%
resource "aws_cloudwatch_metric_alarm" "cloudfront_errors" {
  alarm_name          = "mythirdspace-cloudfront-error-rate"
  alarm_description   = "CloudFront 5xx error rate exceeded 5%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300 # check every 5 minutes
  statistic           = "Average"
  threshold           = 5 # alert if over 5% errors

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.alerts.arn] # notify via SNS

  tags = {
    Project = var.project
  }
}

# CloudWatch alarm — triggers if Lambda errors exceed 5 in 5 minutes
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "mythirdspace-lambda-errors"
  alarm_description   = "Lambda signup function errors exceeded threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Project = var.project
  }
}

# CloudWatch alarm — RDS CPU over 80%
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "mythirdspace-rds-cpu"
  alarm_description   = "RDS CPU utilisation exceeded 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Project = var.project
  }
}

# SNS topic — receives alarm notifications and forwards to email
resource "aws_sns_topic" "alerts" {
  name = "mythirdspace-alerts"

  tags = {
    Project = var.project
  }
}

# SNS subscription — sends alarm emails to your address
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "dommo1998@gmail.com"
}

# Amazon Managed Grafana workspace
resource "aws_grafana_workspace" "website" {
  name                     = "mythirdspace-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH"]
  role_arn                 = aws_iam_role.grafana.arn

  tags = {
    Project = var.project
  }
}

# IAM role — gives Grafana permission to read CloudWatch metrics
resource "aws_iam_role" "grafana" {
  name = "mythirdspace-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "grafana.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = var.project
  }
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
