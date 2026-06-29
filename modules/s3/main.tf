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


resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
    bucket = aws_s3_bucket.website.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256" # encrypts all objects at rest in S3
        }
    }
}
