# =============================================================================
# TERRAGRUNT STACK - AWS INFRASTRUCTURE PRESETS
# =============================================================================
# Preset: eks
# =============================================================================

# -----------------------------------------------------------------------------
# FUNDAMENTAL COMPONENTS (all presets)
# -----------------------------------------------------------------------------

unit "vpc" {
  # #fundamental
  source = "../../../../units/vpc"
  path = "vpc"

  values = {
    preset = "eks"
    # TODO: Add VPC configuration
  }
}

unit "core_sg" {
  # #fundamental
  source = "../../../../units/sg"
  path = "core-sg"

  values = {
    preset = "eks"
    # TODO: Add core security group configuration
  }
}

# -----------------------------------------------------------------------------
# WEB COMPONENTS (webapp + eks presets)
# -----------------------------------------------------------------------------


unit "web_sg" {
  # #web
  source = "../../../../units/sg"
  path = "web-sg"

  values = {
    preset = "eks"
    # TODO: Add web security group configuration
  }
}

unit "alb" {
  # #web
  source = "../../../../units/alb"
  path = "alb"

  values = {
    preset = "eks"
    # TODO: Add Application Load Balancer configuration
  }
}


# -----------------------------------------------------------------------------
# WEBAPP-SPECIFIC COMPONENTS
# -----------------------------------------------------------------------------



# -----------------------------------------------------------------------------
# EKS-SPECIFIC COMPONENTS
# -----------------------------------------------------------------------------


unit "eks_cluster_sg" {
  # #eks
  source = "../../../../units/sg"
  path = "eks-cluster-sg"

  values = {
    preset = "eks"
    # TODO: Add EKS cluster security group configuration
  }
}

unit "eks_node_sg" {
  # #eks
  source = "../../../../units/sg"
  path = "eks-node-sg"

  values = {
    preset = "eks"
    # TODO: Add EKS node security group configuration
  }
}

unit "eks" {
  # #eks
  source = "../../../../units/eks"
  path = "eks"

  values = {
    preset = "eks"
    # TODO: Add EKS cluster configuration
  }
}

unit "aws_load_balancer_controller" {
  # #eks
  source = "../../../../units/k8s-addon"
  path = "aws-load-balancer-controller"

  values = {
    preset = "eks"
    addon_type = "aws-load-balancer-controller"
    # TODO: Add AWS Load Balancer Controller configuration
  }
}

unit "cluster_autoscaler" {
  # #eks
  source = "../../../../units/k8s-addon"
  path = "cluster-autoscaler"

  values = {
    preset = "eks"
    addon_type = "cluster-autoscaler"
    # TODO: Add Cluster Autoscaler configuration
  }
}


# =============================================================================
# PRESET SUMMARY
# foundation:  vpc, core_sg (2 units)
# webapp:      + web_sg, alb, app_sg, db_sg, rds, s3, cloudfront, waf (10 units)
# eks:         + web_sg, alb, eks_cluster_sg, eks_node_sg, eks, aws_load_balancer_controller, cluster_autoscaler (9 units)
# =============================================================================