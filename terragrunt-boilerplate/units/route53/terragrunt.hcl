include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-route53?ref=v4.1.0"
}

dependency "cloudfront" {
  config_path = values.cloudfront_path
  mock_outputs = {
    cloudfront_distribution_domain_name    = "d123456789.cloudfront.net"
    cloudfront_distribution_hosted_zone_id = "Z2FDTNDATAQYW2"
  }
}

inputs = {
  zones = try(values.zones, {})

  records = concat(
    [
      for domain in try(values.domain_names, []) : {
        zone_id = try(values.hosted_zone_id, null)
        name    = domain
        type    = "A"
        alias = {
          name    = dependency.cloudfront.outputs.cloudfront_distribution_domain_name
          zone_id = dependency.cloudfront.outputs.cloudfront_distribution_hosted_zone_id
        }
      }
    ],
    try(values.enable_ipv6, true) ? [
      for domain in try(values.domain_names, []) : {
        zone_id = try(values.hosted_zone_id, null)
        name    = domain
        type    = "AAAA"
        alias = {
          name    = dependency.cloudfront.outputs.cloudfront_distribution_domain_name
          zone_id = dependency.cloudfront.outputs.cloudfront_distribution_hosted_zone_id
        }
      }
    ] : [],

    try(values.additional_records, [])
  )

  tags = try(values.tags, {})
}