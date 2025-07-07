{ { if contains.EnabledUnits "vpc" } }
unit "vpc" {
  source = "../../../../units/vpc"
  path   = "vpc"

  values = {
    cidr                   = "10.1.0.0/16"
    private_subnets        = ["10.1.0.0/20", "10.1.16.0/20", "10.1.32.0/20"]
    public_subnets         = ["10.1.48.0/24", "10.1.49.0/24", "10.1.50.0/24"]
    enable_nat_gateway     = true
    single_nat_gateway     = true
    create_egress_only_igw = true
    enable_dns_hostnames   = true
    enable_dns_support     = true
    region                 = "{{.ManagementRegion}}"
    azs                    = ["{{.ManagementRegion}}a", "{{.ManagementRegion}}b", "{{.ManagementRegion}}c"]
  }
}
{ { end } }

{ { if and(contains.EnabledUnits "sg") (contains.EnabledUnits "vpc") } }
unit "web_sg" {
  source = "../../../../units/sg"
  path   = "web-sg"

  values = {
    name        = "management-web-security-group"
    description = "Security group for web servers in management"
    vpc_path    = "../vpc"

    ingress_with_cidr_blocks = [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        description = "HTTP"
        cidr_blocks = "0.0.0.0/0"
      },
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        description = "HTTPS"
        cidr_blocks = "0.0.0.0/0"
      },
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "SSH"
        cidr_blocks = "10.1.0.0/16"
      }
    ]

    egress_with_cidr_blocks = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        description = "All outbound traffic"
        cidr_blocks = "0.0.0.0/0"
      }
    ]

    tags = {
      Name        = "management-web-security-group"
      Purpose     = "web-servers"
      Environment = "management"
    }
  }
}
{ { end } }