{ { if contains.EnabledUnits "vpc" } }
unit "vpc" {
  source = "../../../../units/vpc"
  path   = "vpc"

  values = {
    cidr                   = "10.3.0.0/16"
    private_subnets        = ["10.3.0.0/20", "10.3.16.0/20", "10.3.32.0/20"]
    public_subnets         = ["10.3.48.0/24", "10.3.49.0/24", "10.3.50.0/24"]
    enable_nat_gateway     = true
    single_nat_gateway     = false
    create_egress_only_igw = true
    enable_dns_hostnames   = true
    enable_dns_support     = true
    region                 = "{{.ProductionRegion}}"
    azs                    = ["{{.ProductionRegion}}a", "{{.ProductionRegion}}b", "{{.ProductionRegion}}c"]
  }
}
{ { end } }

{ { if and(contains.EnabledUnits "sg") (contains.EnabledUnits "vpc") } }
unit "web_sg" {
  source = "../../../../units/sg"
  path   = "web-sg"

  values = {
    name        = "production-web-security-group"
    description = "Security group for web servers in production"
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
        description = "SSH - Restricted"
        cidr_blocks = "10.3.0.0/16"
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
      Name        = "production-web-security-group"
      Purpose     = "web-servers"
      Environment = "production"
    }
  }
}
{ { end } }