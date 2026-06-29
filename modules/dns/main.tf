resource "aws_route53_record" "apex" { # mythirdspace.co.uk
    zone_id = var.zone_id
    name    = var.domain_name
    type    = "A"

    alias {
      name                   = var.cloudfront_distribution_domain_name
      zone_id                = var.cloudfront_hosted_zone_id
      evaluate_target_health = false
    }
}

resource "aws_route53_record" "www" {
    zone_id = var.zone_id
    name    = var.www_domain_name
    type    = "A"

    alias {
      name                   = var.cloudfront_distribution_domain_name
      zone_id                = var.cloudfront_hosted_zone_id
      evaluate_target_health = false
    }
}

/*
Process:
A alias records — points both mythirdspace.co.uk and www at CloudFront
*/
