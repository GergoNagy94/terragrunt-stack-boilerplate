{{- $azMap := map "us-east-1" (list "us-east-1a" "us-east-1b" "us-east-1c") "eu-west-1" (list "eu-west-1a" "eu-west-1b" "eu-west-1c") "ap-southeast-1" (list "ap-southeast-1a" "ap-southeast-1b" "ap-southeast-1c") -}}
{{- $azs := index $azMap .Region -}}
unit "vpc" {
  source = "../../../../units/vpc"

  path = "vpc"

  values = {
    cidr                   = "{{.VpcCidr}}"
    private_subnets        = {{.PrivateSubnets | jsonEncode}}
    public_subnets         = {{.PublicSubnets | jsonEncode}}
    enable_nat_gateway     = true
    single_nat_gateway     = true
    create_egress_only_igw = true
    enable_dns_hostnames   = true
    enable_dns_support     = true
    region                 = "{{.Region}}"
    azs                    = {{$azs | jsonEncode}}
  }
}

unit "web_sg" {
  source = "../../../../units/sg"

  path = "web-sg"

  values = {
    name        = "web-security-group"
    description = "Security group for web servers"
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
        cidr_blocks = "{{.VpcCidr}}"
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
      Name        = "web-security-group"
      Purpose     = "web-servers"
      Environment = "{{.Environment}}"
      Project     = "{{.ProjectName}}"
    }
  }
}