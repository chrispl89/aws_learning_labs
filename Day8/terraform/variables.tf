# Global
variable "project" {
  type    = string
  default = "aws-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_profile" {
  type    = string
  default = "krzysztof-admin"
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

# CloudFront defaults (no custom domain in Day 8)
variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

# Content
variable "index_html_content" {
  description = "Content for index.html uploaded to S3"
  type        = string
  default     = "Hello from Day 8 (S3 + CloudFront + OAC)!"
}
