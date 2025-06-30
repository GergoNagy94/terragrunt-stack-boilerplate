locals {
    project         = "{{.ProjectName}}"
    project_version = "{{.ProjectVersion}}"

    organization_id        = "{{.OrganizationId}}"
    organization_root_id   = "{{.OrganizationRootId}}"

    management_account_id     = "{{.ManagementAccountId}}"
    management_account_email  = "{{.ManagementAccountEmail}}"
    monitoring_account_id     = "{{.MonitoringAccountId}}"
    monitoring_account_email  = "{{.MonitoringAccountEmail}}"
    production_account_id     = "{{.ProductionAccountId}}"
    production_account_email  = "{{.ProductionAccountEmail}}"
    development_account_id    = "{{.DevelopmentAccountId}}"
    development_account_email = "{{.DevelopmentAccountEmail}}"
}