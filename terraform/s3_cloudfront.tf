# S3 Bucket for DRM Encrypted HLS Video Chunks
resource "aws_s3_bucket" "protected_media" {
  bucket = "englishhive-protected-media-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.protected_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.protected_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "englishhive-media-oac"
  description                       = "OAC for encrypted media S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for High-Speed Global Stream Delivery
resource "aws_cloudfront_distribution" "media_cdn" {
  origin {
    domain_name              = aws_s3_bucket.protected_media.bucket_regional_domain_name
    origin_id                = "S3-ProtectedMedia"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "EnglishHive Protected HLS Stream CDN"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-ProtectedMedia"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100" # Lowest cost US/Europe tier
}
