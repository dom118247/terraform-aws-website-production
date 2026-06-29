output "cloudfront_url" {
    description = "CloudFront distribution URL — use this to test before DNS propagates"
    value       = "https://${module.cloudfront.distribution_domain_name}"
}

output "cloudfront_distribution_id" {
    description = "Distribution ID — needed for cache invalidations in CI"
    value       = module.cloudfront.distribution_id
}

output "s3_bucket_name" {
    description = "S3 bucket name — used in CI to upload files"
    value       = module.s3.bucket_name
}

output "api_endpoint" {
    description = "API Gateway endpoint — replace YOUR_API_GATEWAY_URL in index.html with this after apply"
    value       = module.api_gateway.invoke_url
}
