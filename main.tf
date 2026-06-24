resource "aws_s3_bucket" "website" { #.website.
    bucket = "mythirdspace-website-prod"

    lifecycle {
        prevent_destroy = true
    }

    tags = {
        Project = var.project
        Purpose = "website-hosting"
    }
}

resource "aws_s3_bucket_versioning" "website_version" { #website ref for this specific local resource
    bucket = aws_s3_bucket.website.id                   #website here referencing bucket from initial bucket 

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_policy" "website" {
    bucket = aws_s3_bucket.website.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid       = "AllowCloudFrontOAC" # label/description for the statement
            Effect    = "Allow" 
            Principal = { # Who this applies to — CloudFront service
                Service = "cloudfront.amazonaws.com"
            }
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.website.arn}/*" #all resources in bucket
            Condition = {
                StringEquals = {
                    "AWS:SourceArn" = aws_cloudfront_distribution.website.arn  
                }
            }
        }]
    })
}

