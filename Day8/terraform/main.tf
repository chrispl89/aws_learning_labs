########################################
# Locals & naming
########################################
locals {
  name_prefix = "${var.project}-${var.environment}"
  bucket_name = "${local.name_prefix}-static-site"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Krzysztof"
    ManagedBy   = "Terraform"
  }
}

########################################
# S3 bucket (private) - no public access
########################################
resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name
  tags   = merge(local.common_tags, { Name = local.bucket_name })
}

# Ownership & ACL (recommended settings)
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "site" {
  depends_on = [aws_s3_bucket_ownership_controls.site]
  bucket     = aws_s3_bucket.site.id
  acl        = "private"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# Upload index.html (simple content)
########################################
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.bucket
  key          = "index.html"
  content      = var.index_html_content
  content_type = "text/html"
  etag         = md5(var.index_html_content)

  # Even if bucket is private, CloudFront (with OAC) will be able to fetch it
  # once we attach a proper bucket policy below.
}

########################################
# CloudFront: Origin Access Control (OAC)
########################################
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for ${aws_s3_bucket.site.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

########################################
# CloudFront Distribution (no custom domain)
########################################
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  comment             = "${local.name_prefix} static site"
  default_root_object = "index.html"
  price_class         = var.price_class

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.site.id}"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # Use AWS managed cache policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    # No origin request policy is required for a basic static site
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use default CloudFront certificate for *.cloudfront.net
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cdn" })
}

########################################
# S3 bucket policy to allow CloudFront (OAC)
########################################
# Allow CloudFront distribution to GET objects from S3 via OAC.
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

########################################
# Helpful notes (null-resources just to force ordering)
########################################
# Ensure policy is applied after distribution exists
resource "null_resource" "ordering" {
  depends_on = [
    aws_cloudfront_distribution.cdn,
    aws_s3_bucket_policy.site
  ]
}
