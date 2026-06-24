output "cloudfront_url" {
    description = "CloudFront distribution URL — use this to test before DNS propagates"
    value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_distribution_id" {
    description = "Distribution ID — needed for cache invalidations in CI"
    value       = aws_cloudfront_distribution.website.id
}

output "s3_bucket_name" {
    description = "S3 bucket name — used in CI to upload files"
    value       = aws_s3_bucket.website.bucket
}