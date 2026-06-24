resource "aws_acm_certificate" "website_acm_certificate" { # Requests a TLS certificate from AWS Certificate Manager for mythirdspace.co.uk and www.mythirdspace.co.uk. This is what enables HTTPS. Without it CloudFront can only serve HTTP.
    provider = aws.us_east_1

    domain_name = var.domain_name
    subject_alternative_names = [var.www_domain_name]
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Project = var.project
    }
}

resource "aws_cloudfront_origin_access_control" "website_access_control" { # OAC = enforces strict, authenticated access between the CDN and backend resources (e.g. s3), If the CDN server does not have the file, it securely fetches it from your backend (the Origin, like an S3 bucket or EC2 instance) and caches it for the next user | Creates the OAC identity — the "badge" CloudFront shows to S3 to prove who it is. S3 checks this badge against the bucket policy before allowing access. Without it, S3 has no way to verify the request is genuinely from your CloudFront distribution. 
    name                              = "mythirdspace-oac" # local name
    origin_access_control_origin_type = "s3" # origin type is S3, as CloudFront is fetching from an S3 bucket
    signing_behavior                  = "always" # every single request CloudFront makes to S3 gets signed
    signing_protocol                  = "sigv4" # SigV4 is AWS's standard request signing algorithm
}

resource "aws_acm_certificate_validation" "website" {
  # Tells Terraform to go to dns.tf, grab the CNAME records that were created there to prove domain ownership, and wait until ACM confirms- 
  # the cert is fully issued. Nothing else moves forward until this is done (~1-2 min).
    provider                = aws.us_east_1
    certificate_arn         = aws_acm_certificate.website_acm_certificate.arn
    validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn] # loops over the CNAME records in dns.tf and passes their FQDNs to confirm validation is complete
}

resource "aws_cloudfront_distribution" "website" { # Starts once cert validation complete, a distribution tells CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery.
    origin {
        domain_name              = aws_s3_bucket.website.bucket_regional_domain_name # regional S3 URL — required for OAC (not the website endpoint)
        origin_id                = "s3-mythirdspace-website-prod" # unique label to identify this origin within the distribution
        origin_access_control_id = aws_cloudfront_origin_access_control.website_access_control.id # attaches the OAC badge so S3 accepts CloudFront requests
    }

    enabled             = true
    is_ipv6_enabled     = true
    aliases             = [var.domain_name, var.www_domain_name] # both mythirdspace.co.uk and www on one distribution
    default_root_object = "index.html"
    price_class         = "PriceClass_100"  # US + Europe edge locations only — cheapest tier

    default_cache_behavior {
      target_origin_id       = "s3-mythirdspace-website-prod"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"] # G-request asks the server to send back a resource / H-server returns only the headers and does not send the body.
      cached_methods         = ["GET", "HEAD"] # only cache read requests

      forwarded_values {
        query_string = false # don't forward query strings to S3
        cookies {
          forward = "none"
        }
      }

      min_ttl = 0
    }

    custom_error_response {
      error_code = 403 # points to index page instead of error
      response_code = 200
      response_page_path = "/index.html"
    }

    viewer_certificate {
        acm_certificate_arn      = aws_acm_certificate.website_acm_certificate.arn # the cert that proves HTTPS is valid for mythirdspace.co.uk
        ssl_support_method       = "sni-only"       # modern HTTPS — serves the right cert per domain without a dedicated IP
        minimum_protocol_version = "TLSv1.2_2021"   # rejects old TLS 1.0/1.1 clients — security best practice
    }

    restrictions {
        geo_restriction {
            restriction_type = "blacklist"
            locations        = ["RU", "CN", "IR", "KP"] # Russia, China, Iran, North Korea
        }
    }

    tags = {
        Project = var.project
    }

    depends_on = [aws_acm_certificate_validation.website] # doesn't create CF distribution until cert validation complete
}

/*
1. ACM Certificate — requests a TLS cert for mythirdspace.co.uk and www.mythirdspace.co.uk. Exists but not issued yet — AWS is waiting for domain ownership proof from dns.tf.

2. OAC — creates the badge CloudFront shows to S3 to prove who it is. Created in parallel with the cert as it has no dependencies.

3. Certificate Validation — waits until ACM confirms the cert is fully issued (~1-2 min). Acts as a gate — nothing moves forward until this is done.

4. CloudFront Distribution — only created once cert is issued (depends_on). Sits in front of S3, serves the site globally, enforces HTTPS, blocks restricted countries, and maps domain names to the distribution.
*/