# AWS WAF Web ACL (DDoS & Anti-Scraping Protection)
resource "aws_wafv2_web_acl" "waf" {
  name        = "englishhive-${var.environment}-waf"
  description = "WAF rules protecting EnglishHive APIs and Video Streams"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFCommonRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "EnglishHiveWAF"
    sampled_requests_enabled   = true
  }
}
