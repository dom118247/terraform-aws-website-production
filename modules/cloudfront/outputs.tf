output "distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.website.arn
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.website.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.website.hosted_zone_id
}
