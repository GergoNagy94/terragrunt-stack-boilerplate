{ { if or(eq.InfrastructurePreset "fundamental") (eq.InfrastructurePreset "eks-auto") (eq.InfrastructurePreset "eks-managed") } }
unit "vpc" {
  source = "../../../../units/vpc"
  path   = "vpc"

  values = {
    name         = "eks-vpc"
    cidr         = "10.0.0.0/16"
    cluster_name = "my-eks-cluster"

    azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_nat_gateway     = true
    single_nat_gateway     = true # Set to false for HA across AZs
    one_nat_gateway_per_az = false

    enable_dns_hostnames = true
    enable_dns_support   = true

    enable_flow_log                      = false
    create_flow_log_cloudwatch_iam_role  = false
    create_flow_log_cloudwatch_log_group = false

    tags = {
      Name                                        = "eks-vpc"
      Environment                                 = "development"
      "kubernetes.io/cluster/my-eks-auto-cluster" = "owned"
    }
  }
}
{ { end } }
{ { if eq.InfrastructurePreset "web" } }
unit "route53_zones" {
  source = "../../../../units/route53-zones"
  path   = "route53-zones"

  values = {
    zones = {
      "example.com" = {
        comment = "Hosted zone for example.com"
        tags = {
          Name = "example.com"
        }
      }
    }

    tags = {
      Name = "my-web-project-dns-zones"
    }
  }
}

unit "acm" {
  source = "../../../../units/acm"
  path   = "acm"

  values = {
    route53_path              = "../route53-zones"
    domain_name               = "example.com"
    subject_alternative_names = ["www.example.com"]
    wait_for_validation       = true

    tags = {
      Name = "my-web-project-ssl"
    }
  }
}

unit "webacl" {
  source = "../../../../units/webacl"
  path   = "webacl"

  values = {
    name  = "my-web-project-waf"
    scope = "CLOUDFRONT"

    rules = [
      {
        name            = "AWSManagedRulesCommonRuleSet"
        priority        = 1
        override_action = "none"
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "CommonRuleSetMetric"
          sampled_requests_enabled   = true
        }
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
    ]

    rate_based_rules = [
      {
        name     = "RateLimitRule"
        priority = 100
        action   = "block"
        limit    = 2000
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "RateLimitRule"
          sampled_requests_enabled   = true
        }
      }
    ]

    tags = {
      Name = "my-web-project-waf"
    }
  }
}

unit "s3" {
  source = "../../../../units/s3"
  path   = "s3"

  values = {
    bucket_name = "my-web-project-static-site-12345"

    website = {
      index_document = "index.html"
      error_document = "error.html"
    }

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false

    attach_policy = true
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "PublicReadGetObject"
          Effect    = "Allow"
          Principal = "*"
          Action    = "s3:GetObject"
          Resource  = "arn:aws:s3:::my-web-project-static-site-12345/*"
        }
      ]
    })

    cors_rule = [
      {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["*"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3000
      }
    ]

    lifecycle_rule = [
      {
        id      = "delete_old_versions"
        enabled = true
        noncurrent_version_expiration = {
          days = 30
        }
      }
    ]

    tags = {
      Name = "my-web-project-static-site"
    }
  }
}

unit "cloudfront" {
  source = "../../../../units/cloudfront"
  path   = "cloudfront"

  values = {
    s3_path                = "../s3"
    webacl_path            = "../webacl"
    acm_path               = "../acm"
    enable_waf             = true
    use_custom_certificate = true

    aliases = ["www.example.com", "example.com"]
    comment = "CloudFront distribution for my web project"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    custom_error_response = [
      {
        error_code         = 404
        response_code      = 404
        response_page_path = "/error.html"
      },
      {
        error_code         = 403
        response_code      = 404
        response_page_path = "/error.html"
      }
    ]

    tags = {
      Name = "my-web-project-cloudfront"
    }
  }
}

unit "route53_records" {
  source = "../../../../units/route53"
  path   = "route53-records"

  values = {
    cloudfront_path = "../cloudfront"

    hosted_zone_id = "<ZONE_ID>" # ACTUAL ZONE FROM BOILERPLATE ID OR DEPENDENCY OUTPUT

    domain_names = ["example.com", "www.example.com"]
    enable_ipv6  = true

    additional_records = [
      {
        zone_id = "<ZONE_ID>" # ACTUAL ZONE ID FROM BOILERPLATE
        name    = "example.com"
        type    = "MX"
        ttl     = 300
        records = ["10 mail.example.com"]
      }
    ]

    tags = {
      Name = "my-web-project-dns-records"
    }
  }
}
{ { end } }
{ { if eq.InfrastructurePreset "eks-auto" } }


{ { end } }
