locals {
  subscription_id_management = "subscription_id"
  default_location           = "germanywestcentral"
  automation_account_name    = "aac-Management-Management-prd-01"
  management_rg_name         = "rg-Management-prd-01"
  management_law_name        = "law-CLIENT_NAME-Management-Managment-01"
  management_group_id        = "alz"

  tags = {
    environment = "prd"
  }

}

# CAF Module Outputs
locals {
  law_output  = module.caf.azurerm_log_analytics_workspace["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}/providers/Microsoft.OperationalInsights/workspaces/${local.management_law_name}"]
  rg_output   = module.caf.azurerm_resource_group["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}"]
  aac_output  = module.caf.azurerm_automation_account["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}/providers/Microsoft.Automation/automationAccounts/${local.automation_account_name}"]
  lals_output = module.caf.azurerm_log_analytics_linked_service["management"]["/subscriptions/${local.subscription_id_management}/resourceGroups/${local.management_rg_name}/providers/Microsoft.OperationalInsights/workspaces/${local.management_law_name}/linkedServices/Automation"]
}

locals {
  active_services = {
    managed_os = true
  }
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

  additional_queries = {
    "alr-prd-unix_heartbeat_time_generated-01" : {
      description                       = "Alert when filesystem of Windows runs out of space"
      query_path                        = "${path.module}/queries/unix_heartbeat_time_generated.kusto"
      time_window                       = "P2D"
      frequency                         = "PT5M"
      query_time_range_override         = "P2D"
      mute_actions_after_alert_duration = "P1D"
    }
  }
}

resource "azurerm_role_assignment" "monitoring_law_reader" {
  for_each             = module.monitor.scheduled_query_rules_v2
  scope                = local.law_output.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = try(each.value.identity[0].principal_id, null)
}

resource "azurerm_role_assignment" "monitoring_reader" {
  for_each             = module.monitor.scheduled_query_rules_v2
  scope                = local.law_output.id
  role_definition_name = "Reader"
  principal_id         = try(each.value.identity[0].principal_id, null)
}