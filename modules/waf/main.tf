# WAF must be created in us-east-1 for CloudFront (same as ACM cert)
resource "aws_wafv2_web_acl" "website" {
  name        = "mythirdspace-waf"
  description = "WAF for mythirdspace CloudFront distribution"
  scope       = "CLOUDFRONT" # CLOUDFRONT or REGIONAL (for API Gateway/ALB)

  default_action {
    allow {} # allow all traffic unless a rule blocks it
  }

  # rule 1 — AWS managed ruleset, blocks common threats (SQLi, XSS, bad bots)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {} # use the rule's default action (block)
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # rule 2 — blocks known bad IPs and anonymous proxies
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "mythirdspace-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Project = var.project
  }
}
