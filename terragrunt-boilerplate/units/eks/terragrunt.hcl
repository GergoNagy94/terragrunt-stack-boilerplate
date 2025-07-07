terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.37.1"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../provider-config/eks/eks.tf")
}

inputs = {
  cluster_version                      = values.eks_cluster_version
  cluster_name                         = "${values.env}-${values.eks_cluster_name}"
  cluster_enabled_log_types            = values.eks_log_types
  cluster_endpoint_public_access       = values.eks_cluster_endpoint_public_access
  cluster_endpoint_private_access      = values.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = values.eks_cluster_endpoint_public_access_cidrs
  vpc_id                               = dependency.vpc.outputs.vpc_id
  subnet_ids                           = dependency.vpc.outputs.private_subnets

  # Authentication
  authentication_mode = "API_AND_CONFIG_MAP"
  access_entries      = values.eks_access_entries

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = dependency.kms.outputs.key_arn
  }

  # Cloudwatch log group
  create_cloudwatch_log_group            = values.eks_create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = values.eks_cloudwatch_log_group_retention_in_days

  # Cluster tags
  cluster_tags                   = values.tags
  cluster_encryption_policy_tags = values.tags
  iam_role_tags                  = values.tags

  # Cluster security group
  cluster_security_group_name = "${values.env}-${values.eks_cluster_name}-cluster-sg"
  cluster_security_group_tags = values.tags

  # Node security group
  node_security_group_name = "${values.env}-${values.eks_cluster_name}-node-sg"
  node_security_group_tags = values.tags

  cluster_addons = {
    coredns = {
      addon_version = values.eks_coredns_addon_version
    }
    kube-proxy = {
      addon_version = values.eks_kube_proxy_addon_version
    }
    vpc-cni = {
      addon_version = values.eks_vpc_cni_addon_version
    }
    aws-ebs-csi-driver = {
      addon_version            = values.eks_aws_ebs_csi_driver_addon_version
      service_account_role_arn = values.eks_aws_ebs_csi_driver_role_arn
    }
  }

  eks_managed_node_groups = {
    "${values.env}-${values.eks_cluster_name}-ng" = {
      description  = "EKS managed general node group launch template"
      disk_size    = values.eks_nodegroup_disk_size
      desired_size = values.eks_nodegroup_desired_size
      min_size     = values.eks_nodegroup_min_size
      max_size     = values.eks_nodegroup_max_size

      ami_release_version = values.eks_nodegroup_ami_release_version

      labels = {
        role = "general"
      }

      instance_types = values.eks_nodegroup_instance_types

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
      capacity_type = values.eks_nodegroup_capacity_type
    }
  }

  tags = {
    Name        = "${values.env}-${values.project}"
    Environment = "${values.env}"
  }
}

dependency "vpc" {
  config_path = "${get_original_terragrunt_dir()}/../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

dependency "kms" {
  config_path = "${get_original_terragrunt_dir()}/../kms"

  mock_outputs = {
    key_arn = "arn:aws:::::"
  }
}

skip = values.skip_module.eks