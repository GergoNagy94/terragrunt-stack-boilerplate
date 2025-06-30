# {{.ProjectName}}

This project uses Terragrunt for Infrastructure as Code management across multiple AWS accounts.

## Environments

- **Development**: Account {{.DevelopmentAccountId}} in {{.DevRegion}}
- **Production**: Account {{.ProductionAccountId}} in {{.ProdRegion}}
- **Management**: Account {{.ManagementAccountId}} in {{.MgmtRegion}}
- **Monitoring**: Account {{.MonitoringAccountId}} in {{.MonRegion}}

## Project Structure

- `infrastructure/`: Contains all Terragrunt configurations
  - `live/`: Environment-specific configurations
  - `project.hcl`: Project-wide variables
  - `root.hcl`: Common Terragrunt configuration
- `units/`: Reusable Terragrunt modules