include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-security-group?ref=v5.3.0"
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id = "vpc-mock123456"
  }
}

inputs = {
  name        = values.name
  description = values.description
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = try(values.ingress_with_cidr_blocks, [])

  egress_with_cidr_blocks = try(values.egress_with_cidr_blocks, [])

  tags = try(values.tags, {})
}