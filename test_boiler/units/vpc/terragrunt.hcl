include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-vpc?ref=6.0.1"
}

inputs = {
  cidr            = values.cidr
  azs             = values.azs
  private_subnets = values.private_subnets
  public_subnets  = values.public_subnets

  create_egress_only_igw = values.create_egress_only_igw
  enable_dns_hostnames   = values.enable_dns_hostnames
  enable_dns_support     = values.enable_dns_support
  enable_nat_gateway     = values.enable_nat_gateway
  single_nat_gateway     = values.single_nat_gateway
}