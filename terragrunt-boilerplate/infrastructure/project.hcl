locals {
    project         = "{{.ProjectName}}"
    project_version = "{{.ProjectVersion}}"

    organization_id        = "{{.OrganizationId}}"
    organization_root_id   = "{{.OrganizationRootId}}"

    management_account_id  = "{{.ManagementAccountId}}"
    monitoring_account_id  = "{{.MonitoringAccountId}}"
    production_account_id  = "{{.ProductionAccountId}}"
    development_account_id = "{{.DevelopmentAccountId}}"

    management_account_email  = "{{.ManagementAccountEmail}}"
    monitoring_account_email  = "{{.MonitoringAccountEmail}}"
    production_account_email  = "{{.ProductionAccountEmail}}"
    development_account_email = "{{.DevelopmentAccountEmail}}"
}