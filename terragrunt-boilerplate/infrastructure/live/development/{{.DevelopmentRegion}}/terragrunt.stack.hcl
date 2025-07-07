# FUNDAMENTAL COMPONENTS (all presets)

unit "vpc" {
  # #fundamental
  source = "../../../../units/vpc"
  path = "vpc"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add VPC configuration
  }
}

unit "core_sg" {
  # #fundamental
  source = "../../../../units/sg"
  path = "core-sg"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add core security group configuration
  }
}

# WEB COMPONENTS (webapp + eks presets)

{{ if or (eq .InfrastructurePreset "webapp") (eq .InfrastructurePreset "eks") }}
unit "web_sg" {
  # #web
  source = "../../../../units/sg"
  path = "web-sg"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add web security group configuration
  }
}

unit "alb" {
  # #web
  source = "../../../../units/alb"
  path = "alb"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add Application Load Balancer configuration
  }
}
{{ end }}

# WEBAPP-SPECIFIC COMPONENTS

{{ if eq .InfrastructurePreset "webapp" }}
unit "app_sg" {
  # #webapp
  source = "../../../../units/sg"
  path = "app-sg"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add application security group configuration
  }
}

unit "db_sg" {
  # #webapp
  source = "../../../../units/sg"
  path = "db-sg"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add database security group configuration
  }
}

unit "rds" {
  # #webapp
  source = "../../../../units/rds"
  path = "rds"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add RDS configuration
  }
}

unit "s3" {
  # #webapp
  source = "../../../../units/s3"
  path = "s3"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add S3 configuration
  }
}

unit "cloudfront" {
  # #webapp
  source = "../../../../units/cloudfront"
  path = "cloudfront"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add CloudFront configuration
  }
}

unit "waf" {
  # #webapp
  source = "../../../../units/waf"
  path = "waf"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add WAF configuration
  }
}
{{ end }}

# EKS-SPECIFIC COMPONENTS

{{ if eq .InfrastructurePreset "eks" }}
unit "eks_cluster_sg" {
  # #eks
  source = "../../../../units/sg"
  path = "eks-cluster-sg"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add EKS cluster security group configuration
  }
}

unit "eks_node_sg" {
  # #eks
  source = "../../../../units/sg"
  path = "eks-node-sg"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add EKS node security group configuration
  }
}

unit "eks" {
  # #eks
  source = "../../../../units/eks"
  path = "eks"

  values = {
    preset = "{{.InfrastructurePreset}}"
    # TODO: Add EKS cluster configuration
  }
}

unit "aws_load_balancer_controller" {
  # #eks
  source = "../../../../units/k8s-addon"
  path = "aws-load-balancer-controller"

  values = {
    preset = "{{.InfrastructurePreset}}"
    addon_type = "aws-load-balancer-controller"
    # TODO: Add AWS Load Balancer Controller configuration
  }
}

unit "cluster_autoscaler" {
  # #eks
  source = "../../../../units/k8s-addon"
  path = "cluster-autoscaler"

  values = {
    preset = "{{.InfrastructurePreset}}"
    addon_type = "cluster-autoscaler"
    # TODO: Add Cluster Autoscaler configuration
  }
}
{{ end }}