data "aws_route53_zone" "website" { # looks up existing Route53 hosted zone by domain name
    name         = var.domain_name
    private_zone = false
}

resource "aws_route53_record" "cert_validation" {
    for_each = { # dvo = domain validation option
        for dvo in aws_acm_certificate.website_acm_certificate.domain_validation_options : dvo.domain_name => # "for each dvo in this list  :  then produce this key => value"
        {                                                                           # KEY -> dvo.domain_name => { VALUES -> name, type, record }
            name    = dvo.resource_record_name
            type    = dvo.resource_record_type
            record  = dvo.resource_record_value
        }
    }

    zone_id = data.aws_route53_zone.website.zone_id # Which hosted zone to create the record in
    name    = each.value.name # www & without
    type    = each.value.type # CNAME
    records = [each.value.record] # CNAME value ACM wants to see in DNS, TF expects list
    ttl     = 60 # how long DNS servers cache this record before checking for updates
}

resource "aws_route53_record" "apex" { # mythirdspace.co.uk
    zone_id = data.aws_route53_zone.website.zone_id
    name    = var.domain_name
    type    = "A"

    alias {
      name                   = aws_cloudfront_distribution.website.domain_name 
      zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
      evaluate_target_health = false
    }
}

resource "aws_route53_record" "www" {
    zone_id = data.aws_route53_zone.website.zone_id
    name    = var.www_domain_name
    type    = "A"

    alias {
      name                   = aws_cloudfront_distribution.website.domain_name 
      zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
      evaluate_target_health = false
    }
}

/*
Process:
Data source — finds existing hosted zone, read-only
Cert validation records — proves to ACM I own the domain so the cert gets issued
A alias records — points both mythirdspace.co.uk and www at CloudFront
*/