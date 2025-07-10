locals {
  env                       = "development"
  region                    = "{{.DevelopmentRegion}}"
  project                   = "{{.ProjectName}}"
  project_version           = "{{.ProjectVersion}}"
  account_type    = "{{.AccountType}}"
  {{- if eq .AccountType "single" }}
  development_account_id    = "{{.DevelopmentAccountId}}"
  development_account_email = "aws+development@{{.EmailDomain}}"
  {{- else }}
  organization_id           = "{{.OrganizationId}}"
  organization_root_id      = "{{.OrganizationRootId}}"

  management_account_id     = "{{.ManagementAccountId}}"
  monitoring_account_id     = "{{.MonitoringAccountId}}"
  production_account_id     = "{{.ProductionAccountId}}"
  development_account_id    = "{{.DevelopmentAccountId}}"

  management_account_email  = "aws+management@{{.EmailDomain}}"
  monitoring_account_email  = "aws+monitoring@{{.EmailDomain}}"
  production_account_email  = "aws+production@{{.EmailDomain}}"
  development_account_email = "aws+development@{{.EmailDomain}}"
  {{- end }}
  tags = {
    Project     = local.project
    Environment = local.env
    Maintaner   = "Terragrunt"
  }
}
{{ if or (eq .InfrastructurePreset "foundation") (eq .InfrastructurePreset "eks-auto") (eq .InfrastructurePreset "eks-managed") (eq .InfrastructurePreset "serverless") }}
unit "vpc" {
  source = "../../../../units/vpc"
  path   = "vpc"

  values = {
    name         = "{local.project}-{local.env}-vpc"
    cidr         = "10.0.0.0/16"
{{ if or (eq .InfrastructurePreset "eks-auto") (eq .InfrastructurePreset "eks-managed") }}
    cluster_name = "{local.project}-{local.env}-cluster"
{{ end }}
{{ if (eq .InfrastructurePreset "serverless") }}    
    database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

    enable_s3_endpoint       = true
    enable_dynamodb_endpoint = true

    public_subnet_tags = {
      Type = "Public"
    }

    private_subnet_tags = {
      Type = "Private"
    }

    database_subnet_tags = {
      Type = "Database"
    }

    create_database_subnet_group       = true
    create_database_subnet_route_table = true
{{ end }}

    azs = ["{local.region}a", "{local.region}b", "{local.region}c"]

    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


    enable_nat_gateway     = true
    single_nat_gateway     = true
    one_nat_gateway_per_az = false

    enable_dns_hostnames = true
    enable_dns_support   = true

    enable_flow_log                      = false
    create_flow_log_cloudwatch_iam_role  = false
    create_flow_log_cloudwatch_log_group = false

    tags = {
      Name                                        = "{local.project}-{local.env}-vpc"
      Environment                                 = "development"
{{ if or (eq .InfrastructurePreset "eks-auto") (eq .InfrastructurePreset "eks-managed") }}
      "kubernetes.io/cluster/{local.project}-cluster" = "owned"
{{ end }}
    }
  }
}
{{ end }}
{{ if eq .InfrastructurePreset "web" }}
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
      Name = "{local.project}-dns-zones"
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
      Name = "{local.project}-ssl"
    }
  }
}

unit "webacl" {
  source = "../../../../units/webacl"
  path   = "webacl"

  values = {
    name  = "{local.project}-waf"
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
      Name = "{local.project}-waf"
    }
  }
}

unit "s3" {
  source = "../../../../units/s3"
  path   = "s3"

  values = {
    bucket_name = "{local.project}-static-site-12345"

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
          Resource  = "arn:aws:s3:::{local.project}-static-site-12345/*"
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
      Name = "{local.project}-static-site"
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
      Name = "{local.project}-cloudfront"
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
      Name = "{local.project}-dns-records"
    }
  }
}
{{ end }}
{{ if eq .InfrastructurePreset "eks-auto" }}
unit "kms" {
  source = "../../../../units/kms"
  path   = "kms"

  values = {
    description = "KMS key for EKS cluster encryption"
    aliases     = ["alias/eks-cluster-encryption"]

    key_administrators = [
      "arn:aws:iam::123456789012:root",
      "arn:aws:iam::123456789012:role/terragrunt-execution-role"
    ]

    deletion_window_in_days = 7

    tags = {
      Name        = "eks-cluster-kms-key"
      Environment = "development"
      Purpose     = "EKS-Encryption"
    }
  }
}

unit "eks" {
  source = "../../../../units/eks"
  path   = "eks"

  values = {
    vpc_path = "../vpc"
    kms_path = "../kms"

    cluster_name    = "{local.project}-auto-cluster"
    cluster_version = "1.31"

    enable_auto_mode              = true
    bootstrap_self_managed_addons = true

    cluster_endpoint_public_access       = true
    cluster_endpoint_private_access      = true
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # RESTRICT IN PRODUCTION

    authentication_mode = "API_AND_CONFIG_MAP"

    access_entries = {
      admin = {
        principal_arn     = "arn:aws:iam::123456789012:role/eks-admin-role" # BOILERPLATE ADMIN ROLE INPUT
        kubernetes_groups = ["system:masters"]
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }

    enable_irsa = true

    enable_kms_encryption = true

    cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    cloudwatch_log_group_retention_in_days = 14
    create_cloudwatch_log_group            = true

    node_pools = ["general-purpose", "system"]

    cluster_security_group_additional_rules = {}
    node_security_group_additional_rules    = {}

    tags = {
      Name        = "{local.project}-auto-cluster"
      Environment = "development"
      ManagedBy   = "Terragrunt"
      EKSMode     = "Auto"
    }
  }
}

unit "ebs_csi_driver" {
  source = "../../../../units/ebs-csi-driver"
  path   = "ebs-csi-driver"

  values = {
    eks_path = "../eks"
    kms_path = "../kms"

    role_name                  = "ebs-csi-driver-role"
    namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]

    enable_kms_encryption = true

    tags = {
      Name        = "ebs-csi-driver-role"
      Environment = "development"
      Purpose     = "EBS-CSI-Driver"
    }
  }
}

unit "aws_load_balancer_controller" {
  source = "../../../../units/aws-lbc"
  path   = "aws-load-balancer-controller"

  values = {
    eks_path = "../eks"

    helm_chart_name         = "aws-load-balancer-controller"
    helm_chart_release_name = "aws-load-balancer-controller"
    helm_chart_repo         = "https://aws.github.io/eks-charts"
    helm_chart_version      = "1.8.4"

    namespace            = "kube-system"
    service_account_name = "aws-load-balancer-controller"

    irsa_role_name_prefix = "aws-load-balancer-controller"

    helm_chart_values = [
      <<-EOT
      clusterName: {local.project}-auto-cluster
      serviceAccount:
        create: true
        name: aws-load-balancer-controller
      region: us-east-1
      vpcId: vpc-placeholder  # Will be populated by the module
      EOT
    ]

    tags = {
      Name        = "aws-load-balancer-controller"
      Environment = "development"
      Purpose     = "Load-Balancer-Controller"
    }
  }
}

unit "additional_iam_roles" {
  source = "../../../../units/iam-role"
  path   = "additional-iam-roles"

  values = {
    eks_path = "../eks"

    role_name = "external-dns-role"

    namespace_service_accounts = ["kube-system:external-dns"]

    attach_external_dns_policy = true

    role_policy_arns = {}

    tags = {
      Name        = "external-dns-role"
      Environment = "development"
      Purpose     = "External-DNS"
    }
  }
}
{{ end }}
{{ if eq .InfrastructurePreset "serverless" }}
unit "secrets_manager" {
  source = "../../../../units/secrets-manager"
  path   = "secrets-manager"

  values = {
    name        = "{local.project}-{local.env}-db-credentials"
    description = "Database credentials for serverless application"

    db_username = "dbadmin"
    db_password = "MySecurePassword123!"

    secret_string = jsonencode({
      username = "dbadmin"
      password = "MySecurePassword123!"
      engine   = "mysql"
      host     = "placeholder" # Will be updated after RDS creation
      port     = 3306
      dbname   = "appdb"
    })

    enable_rotation = false

    recovery_window_in_days = 7
    ignore_secret_changes   = true

    block_public_policy = true

    tags = {
      Name        = "{local.project}-{local.env}-db-credentials"
      Environment = "development"
      Purpose     = "Database-Credentials"
    }
  }
}

unit "rds" {
  source = "../../../../units/rds-lambda"
  path   = "rds"

  values = {
    vpc_path             = "../vpc"
    secrets_manager_path = "../secrets-manager"

    identifier = "{local.project}-{local.env}-db"

    engine               = "mysql"
    engine_version       = "8.0.39"
    major_engine_version = "8.0"
    family               = "mysql8.0"
    instance_class       = "db.t3.micro" # INCREASE FOR PRODUCTION

    allocated_storage     = 20
    max_allocated_storage = 100
    storage_type          = "gp3"
    storage_encrypted     = true

    db_name  = "appdb"
    username = "dbadmin"

    manage_master_user_password = true

    create_db_parameter_group = true
    create_db_option_group    = false

    backup_retention_period = 7
    backup_window           = "03:00-04:00"
    maintenance_window      = "sun:04:00-sun:05:00"

    monitoring_interval    = 60
    create_monitoring_role = true

    performance_insights_enabled          = true
    performance_insights_retention_period = 7

    multi_az = false # SET TO TRUE FOR PROD

    deletion_protection = false # SET TO TRUE FOR PROD
    skip_final_snapshot = true  # SET TO FALSE FOR PROD

    parameters = [
      {
        name  = "innodb_buffer_pool_size"
        value = "{DBInstanceClassMemory*3/4}"
      },
      {
        name  = "max_connections"
        value = "1000"
      }
    ]

    tags = {
      Name        = "{local.project}-{local.env}-database"
      Environment = "development"
      Purpose     = "Application-Database"
    }
  }
}

unit "lambda" {
  source = "../../../../units/lambda"
  path   = "lambda"

  values = {
    vpc_path             = "../vpc"
    rds_path             = "../rds"
    secrets_manager_path = "../secrets-manager"

    function_name = "{local.project}-app"
    description   = "Main serverless application function"
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.11"
    timeout       = 30
    memory_size   = 512

    source_path    = "./src" # PATH TO LAMBDA SOURCE CODE
    create_package = true

    # Option 2: S3 source code
    # s3_bucket = "my-lambda-deployments"
    # s3_key    = "{local.project}-{local.env}/lambda.zip"

    environment_variables = {
      LOG_LEVEL          = "INFO"
      ENVIRONMENT        = "development"
      APP_NAME           = "{local.project}-app"
      DB_CONNECTION_POOL = "10"
    }

    reserved_concurrent_executions = -1

    layers = []

    cloudwatch_logs_retention_in_days = 14

    tracing_config_mode = "Active"

    tags = {
      Name        = "{local.project}-app"
      Environment = "development"
      Purpose     = "Main-Application-Function"
    }
  }
}

unit "api_gateway" {
  source = "../../../../units/api-gateway"
  path   = "api-gateway"

  values = {
    lambda_path = "../lambda"

    name        = "{local.project}-api"
    description = "HTTP API for {local.project} application"

    cors_configuration = {
      allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
      allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      allow_origins     = ["*"] # RESTRICT IN PRODUCTION
      expose_headers    = ["date", "keep-alive"]
      max_age           = 86400
      allow_credentials = false
    }

    # Domain configuration
    # domain_name                 = "api.yourdomain.com"
    # domain_name_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    # create_api_domain_name      = true

    default_route_settings = {
      detailed_metrics_enabled = true
      throttling_burst_limit   = 1000
      throttling_rate_limit    = 500
    }

    access_log_format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      error            = "$context.error.message"
      integrationError = "$context.integration.error"
    })

    tags = {
      Name        = "{local.project}-api"
      Environment = "development"
      Purpose     = "Application-API"
    }
  }
}
{{ end }}