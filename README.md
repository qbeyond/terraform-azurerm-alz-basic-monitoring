# Module
[![GitHub tag](https://img.shields.io/github/tag/qbeyond/terraform-module-template.svg)](https://registry.terraform.io/modules/qbeyond/terraform-module-template/provider/latest)
[![License](https://img.shields.io/github/license/qbeyond/terraform-module-template.svg)](https://github.com/qbeyond/terraform-module-template/blob/main/LICENSE)

----

This is a template module. It just showcases how a module should look. This would be a short description of the module.

<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-basic-monitoring

## Description

This Terraform module deploys a basic Azure Monitor baseline for a Log Analytics Workspace.

The module creates:

- An Azure Monitor Action Group with configurable email receivers.
- Azure Monitor Scheduled Query Rules v2 for common monitoring scenarios.
- Built-in Data Collection Rules (DCRs) for:
  - VM Insights
  - Windows Event Logs
  - Linux Syslog
- Optional managed identities for alert rules using:
  - `SystemAssigned`
  - `UserAssigned`

This module is a simplified Azure monitoring baseline focused on reusable alerting and core data collection for managed workloads.

## Features

- Creates one Azure Monitor Action Group for email notifications.
- Creates scheduled query alert rules from predefined KQL files.
- Supports optional managed identity on `azurerm_monitor_scheduled_query_rules_alert_v2`.
- Exposes a stable output for downstream RBAC assignments when alert rules use `SystemAssigned` identity.
- Creates built-in DCRs for VM Insights, Windows Event Logs, and Linux Syslog.
- Enables additional Windows event-based alerting when one or more services are enabled in `active_services`.

## Built-in alert rules

The module includes these baseline alert rules:

- Unix heartbeat
- Unix filesystem usage
- Windows heartbeat
- Windows filesystem free space
- Windows event log alerting when `active_services` selects event definitions

The KQL queries target Azure VMs, Arc-enabled servers, and VM scale sets tagged with `alerting = enabled`.

## Built-in DCRs

The module creates these built-in Data Collection Rules:

- `vm_insight`
- `event_log`
- `syslog`
- `syslog_notice`

> Note:
> In the current implementation, these built-in DCRs are created with `SystemAssigned` identity.

## Requirements

| Name | Version |
|---|---|
| terraform | `>= 1.5.0` |
| azurerm | `>= 3.100.0` |
| azapi | `~> 1.14` |

## Providers

| Name | Version |
|---|---|
| azurerm | `>= 3.100.0` |
| azapi | `~> 1.14` |

## Usage

### Example with System Assigned identity on alert rules

```hcl
locals {
  subscription_id_management = "subscription_id"
  default_location           = "germanywestcentral"
  management_rg_name         = "rg-Management-prd-01"
  management_law_name        = "law-CLIENT_NAME-Management-Managment-01"

  tags = {
    environment = "prd"
    workload    = "monitoring"
  }

  active_services = {
    managed_os = true
  }
}

locals {
  law_output = module.caf.azurerm_log_analytics_workspace["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}/providers/Microsoft.OperationalInsights/workspaces/${local.management_law_name}"]
}

module "monitoring" {
  source = "./modules/monitoring"

  log_analytics_workspace = local.law_output
  tags                    = local.tags
  active_services         = local.active_services

  alert_rule_identity = {
    type = "SystemAssigned"
  }

  email_receivers = [
    {
      name          = "ITTeam"
      email_address = "it@business.com"
    }
  ]
}

resource "azurerm_role_assignment" "monitoring_law_reader" {
  for_each = module.monitoring.alert_rules_for_role_assignments

  scope                = local.law_output.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = each.value.principal_id
}
```

### Example with User Assigned identity on alert rules

```hcl
locals {
  subscription_id_management = "subscription_id"
  default_location           = "germanywestcentral"
  management_rg_name         = "rg-Management-prd-01"
  management_law_name        = "law-CLIENT_NAME-Management-Managment-01"

  tags = {
    environment = "prd"
    workload    = "monitoring"
  }

  active_services = {
    managed_os = true
  }
}

locals {
  law_output = module.caf.azurerm_log_analytics_workspace["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}/providers/Microsoft.OperationalInsights/workspaces/${local.management_law_name}"]
  rg_output  = module.caf.azurerm_resource_group["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}"]
}

resource "azurerm_user_assigned_identity" "monitoring_umi" {
  name                = "umi-prd-ManagementMonitoring-01"
  location            = local.default_location
  resource_group_name = local.rg_output.name
}

resource "azurerm_role_assignment" "monitoring_umi_law_reader" {
  scope                = local.law_output.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.monitoring_umi.principal_id
}

module "monitoring" {
  source = "./modules/monitoring"

  log_analytics_workspace = local.law_output
  tags                    = local.tags
  active_services         = local.active_services

  alert_rule_identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.monitoring_umi.id]
  }

  email_receivers = [
    {
      name          = "ITTeam"
      email_address = "it@business.com"
    }
  ]
}
```

## Managed identities

### Alert rules

The module supports optional managed identity on alert rules through `alert_rule_identity`.

Supported values:

- `SystemAssigned`
- `UserAssigned`

For `UserAssigned`, provide one or more Azure resource IDs in `identity_ids`.

Example:

```hcl
alert_rule_identity = {
  type         = "UserAssigned"
  identity_ids = [azurerm_user_assigned_identity.monitoring_umi.id]
}
```

If `alert_rule_identity` is `null`, the alert rules are deployed without a managed identity.

### DCRs

The built-in DCR resources currently use:

```hcl
identity {
  type = "SystemAssigned"
}
```

This means the built-in DCR identities are not parameterized in the current implementation.

## RBAC model

RBAC assignments for managed identities should be created **outside** the module.

This keeps the module reusable and avoids hidden privilege assignments inside the monitoring module.

### System Assigned alert rules

When alert rules use `SystemAssigned`, the module exposes:

- `alert_rules_for_role_assignments`

This output is designed for downstream `for_each` usage because it is keyed by statically known alert rule names.

Example shape:

```hcl
{
  "alr-prd-Heartbeat-ux-law-metric-crit-01" = {
    principal_id = "..."
  }
}
```

Example role assignment:

```hcl
resource "azurerm_role_assignment" "monitoring_law_reader" {
  for_each = module.monitoring.alert_rules_for_role_assignments

  scope                = local.law_output.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = each.value.principal_id
}
```

### User Assigned alert rules

When alert rules use `UserAssigned`, assign RBAC directly to the User Assigned Identity resource and then pass its resource ID into the module.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `log_analytics_workspace` | Log Analytics Workspace object used by alerts and DCRs. | `object({ id = string, name = string, resource_group_name = string, location = string, workspace_id = string })` | n/a | yes |
| `tags` | Tags assigned to all created resources. | `map(string)` | `{}` | no |
| `active_services` | Enables event monitoring categories used by the alert query templates. | `object({ active_directory = optional(bool, false), managed_os = optional(bool, false), mssql = optional(bool, false) })` | `{}` | no |
| `email_receivers` | Email receivers for the Azure Monitor Action Group. | `list(object({ name = string, email_address = string, use_common_alert_schema = optional(bool, true) }))` | `[]` | no |
| `alert_rule_identity` | Managed identity configuration for alert rules. Supports `SystemAssigned` or `UserAssigned`. | `object({ type = string, identity_ids = optional(list(string), []) })` | `null` | no |

## Outputs

| Name | Description |
|---|---|
| `action_group_id` | ID of the Azure Monitor Action Group created for notifications. |
| `windows_dcr_ids` | Resource ID list of the Windows Event Log DCR. |
| `linux_dcr_ids` | Resource ID list of the Linux Syslog DCR. |
| `vminsights_dcr_id` | Resource ID of the VM Insights DCR. |
| `alert_rules_for_role_assignments` | Alert rules keyed by statically known names with their principal IDs. Only populated when alert rules use `SystemAssigned` identity. |

## Queries

The module uses these query files:

- `queries/unix_heartbeat.kusto`
- `queries/unix_filespace.kusto`
- `queries/windows_heartbeat.kusto`
- `queries/windows_filespace.kusto`
- `queries/windows_event.kusto.tftpl`

## Notes

- The event log alert rule is added only when `active_services` selects one or more event categories.
- The alert rules are created from `local.all_alertrules`.
- The module uses one Action Group for all scheduled query alerts.
- The current built-in DCR implementation is still fixed to `SystemAssigned` identity.
- `alert_rules_for_role_assignments` is the preferred output for downstream RBAC on system-assigned alert identities.

## Limitations

- This is a basic monitoring module and not a full ALZ monitoring implementation.
- Built-in DCR identities are not configurable in the current code.
- Role assignments are intentionally managed outside the module.
- Alert queries are based on the query files shipped with the module.

## References

- AzureRM resource `azurerm_monitor_scheduled_query_rules_alert_v2`
- AzureRM resource `azurerm_monitor_data_collection_rule`
- Azure Monitor log alerts
- Azure Monitor Data Collection Rules
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).