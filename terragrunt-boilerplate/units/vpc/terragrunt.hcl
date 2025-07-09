include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-vpc?ref=v5.13.0"
}

inputs = {
  name = values.name
  cidr = values.cidr

  azs             = values.azs
  private_subnets = values.private_subnets
  public_subnets  = values.public_subnets

  enable_nat_gateway     = try(values.enable_nat_gateway, true)
  single_nat_gateway     = try(values.single_nat_gateway, true)
  one_nat_gateway_per_az = try(values.one_nat_gateway_per_az, false)

  enable_dns_hostnames = try(values.enable_dns_hostnames, true)
  enable_dns_support   = try(values.enable_dns_support, true)

  enable_flow_log                      = try(values.enable_flow_log, false)
  create_flow_log_cloudwatch_iam_role  = try(values.create_flow_log_cloudwatch_iam_role, false)
  create_flow_log_cloudwatch_log_group = try(values.create_flow_log_cloudwatch_log_group, false)

  public_subnet_tags = merge(
    try(values.public_subnet_tags, {}),
    {
      "kubernetes.io/role/elb"                       = "1"
      "kubernetes.io/cluster/${values.cluster_name}" = "owned"
    }
  )

  private_subnet_tags = merge(
    try(values.private_subnet_tags, {}),
    {
      "kubernetes.io/role/internal-elb"              = "1"
      "kubernetes.io/cluster/${values.cluster_name}" = "owned"
    }
  )

  tags = try(values.tags, {})
}