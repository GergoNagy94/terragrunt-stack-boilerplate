# {{.ProjectName}}

Multi-account AWS infrastructure using Terragrunt and OpenTofu.

## Project Structure
{{.ProjectName}}/
├── infrastructure/
│   ├── live/                    # Live environment configurations
{{- if .CreateDevelopment}}
│   │   ├── development/         # Development environment
{{- end}}
{{- if .CreateProduction}}
│   │   ├── production/          # Production environment
{{- end}}
{{- if .CreateManagement}}
│   │   ├── management/          # Management environment
{{- end}}
{{- if .CreateMonitoring}}
│   │   └── monitoring/          # Monitoring environment
{{- end}}
│   ├── project.hcl              # Project-wide configuration
│   └── root.hcl                 # Common Terragrunt configuration
├── units/                       # Reusable Terragrunt units
│   ├── vpc/                     # VPC unit
│   └── sg/                      # Security Group unit
└── mise.toml                    # Tool version management

## Prerequisites

- [mise](https://mise.jdx.dev/) for tool version management
- AWS CLI configured with appropriate credentials
- Access to AWS accounts for each environment

## Getting Started

1. Install tools using mise:
mise install

2. Initialize the project:
cd infrastructure/live/development/eu-west-1
terragrunt run-all init

3. Plan the infrastructure:
terragrunt run-all plan

4. Apply the infrastructure:
terragrunt run-all apply