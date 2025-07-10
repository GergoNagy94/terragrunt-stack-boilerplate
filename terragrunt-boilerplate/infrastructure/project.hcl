locals {
  project         = "{{.ProjectName}}"
  project_version = "{{.ProjectVersion}}"
  account_type    = "{{.AccountType}}"

  {{- if eq .AccountType "single" }}

  development_account_id = "{{.DevelopmentAccountId}}"
  development_account_email = "aws+development@{{.EmailDomain}}"

  {{- else }}
  organization_id      = "{{.OrganizationId}}"
  organization_root_id = "{{.OrganizationRootId}}"

  management_account_id  = "{{.ManagementAccountId}}"
  monitoring_account_id  = "{{.MonitoringAccountId}}"
  production_account_id  = "{{.ProductionAccountId}}"
  development_account_id = "{{.DevelopmentAccountId}}"

  management_account_email  = "aws+management@{{.EmailDomain}}"
  monitoring_account_email  = "aws+monitoring@{{.EmailDomain}}"
  production_account_email  = "aws+production@{{.EmailDomain}}"
  development_account_email = "aws+development@{{.EmailDomain}}"

  {{- end }}
}