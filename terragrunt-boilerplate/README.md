# {{.ProjectName}}

This project uses Terragrunt for Infrastructure as Code management across multiple AWS accounts.

## Environments

- **Development**: Account {{.DevelopmentAccountId}} in {{.DevelopmentRegion}}
- **Production**: Account {{.ProductionAccountId}} in {{.ProductionRegion}}
- **Management**: Account {{.ManagementAccountId}} in {{.ManagementRegion}}
- **Monitoring**: Account {{.MonitoringAccountId}} in {{.MonitoringRegion}}

## Project Structure

- `infrastructure/`: Contains all Terragrunt configurations
- `live/`: Environment-specific configurations
- `project.hcl`: Project-wide variables
- `root.hcl`: Common Terragrunt configuration
- `units/`: Reusable Terragrunt modules

## Install OpenTofu and Terragrunt

use 'mise install' command to install tools
