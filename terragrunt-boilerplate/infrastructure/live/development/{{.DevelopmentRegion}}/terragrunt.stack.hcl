# FUNDAMENTAL COMPONENTS (all presets)

unit "vpc" {
  # #fundamental
  source = "../../../../units/vpc"
  path = "vpc"

  values = {
    preset = "{{.InfrastructurePreset}}"
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
  }
}

# WEBAPP-SPECIFIC COMPONENTS

{{ if eq .InfrastructurePreset "webapp" }}
unit "cloudfront" {
  # #webapp
  source = "../../../../units/cloudfront"
  path = "cloudfront"

  values = {
    preset = "{{.InfrastructurePreset}}"
  }
}
{{ end }}

# EKS-SPECIFIC COMPONENTS

{{ if eq .InfrastructurePreset "eks" }}

unit "aws_load_balancer_controller" {
  # #eks
  source = "../../../../units/k8s-addon"
  path = "aws-load-balancer-controller"

  values = {
    preset = "{{.InfrastructurePreset}}"
    addon_type = "aws-load-balancer-controller"
  }
}
{{ end }}
