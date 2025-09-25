output "s3_bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "site_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}
