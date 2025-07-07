# my-project - Terragrunt Stack

This is a Terragrunt stack monorepo for my-project infrastructure.

## Overview

- **Project**: my-project
- **Version**: v1.0.0
- **Created**: 2025-07-07
- **Created By**: nagygergo

## Environment Configuration

Environment: Development    Region: 12      Account ID: 12 
Environment: Management     Region: 12       Account ID: 12  
Environment: Monitoring     Region: 12       Account ID: 12  
Environment: Production     Region: 12       Account ID: 12  

## Project Structure

```
.
├── infrastructure/
│   ├── root.hcl            # Common Terragrunt configuration
│   ├── project.hcl         # Project-specific variables
│   └── live/               # Environment-specific configurations
│       ├── development/
│       ├── management/
│       ├── monitoring/
│       └── production/
└── units/                  # Reusable Terragrunt units
    ├── vpc/
    └── sg/
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- OpenTofu 1.10.2
- Terragrunt 0.82.3
- [mise](https://mise.jdx.dev/) (for tool version management)

## Getting Started

1. Install mise and required tools:
```bash
mise trust
mise install
```

2. Configure AWS credentials for each account:
```bash
aws configure --profile my-project-development
aws configure --profile my-project-management
aws configure --profile my-project-monitoring
aws configure --profile my-project-production
```

3. Deploy infrastructure:
```bash
cd infrastructure/live/development/12
AWS_PROFILE=my-project-development terragrunt run-all apply

AWS_PROFILE=my-project-development terragrunt apply --terragrunt-working-dir vpc
```

## Adding New Units

To add a new unit to the stack:

1. Add the unit configuration to `units/` directory
3. Regenerate the stack files or manually add the unit to `terragrunt.stack.hcl`

## Security Considerations

- All environments use IAM role assumption with `terragrunt-execution-role`
- State files are encrypted in S3
- DynamoDB tables are used for state locking
- Separate AWS accounts for each environment

## Troubleshooting

### Common Issues

1. **State bucket doesn't exist**: Create the S3 bucket before running Terragrunt
2. **IAM role not found**: Ensure the `terragrunt-execution-role` exists in each account
3. **Region mismatch**: Verify the region settings in `region.hcl` files

### Debug Commands

```bash
TG_LOG=debug terragrunt plan

terragrunt validate

terragrunt dag graph
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test in development environment
4. Submit a pull request