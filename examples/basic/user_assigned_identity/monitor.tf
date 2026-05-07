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

resource "azurerm_user_assigned_identity" "monitoring_umi" {
  name                = "umi-prd-ManagementMonitoring-01"
  location            = local.default_location
  resource_group_name = local.rg_output.name
}

resource "azurerm_role_assignment" "alert_monitoring_log_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.monitoring_umi.principal_id
}

resource "azurerm_role_assignment" "alert_monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.monitoring_umi.principal_id
}

module "monitoring" {
  source = "./modules/monitoring"

  log_analytics_workspace = local.law_output
  tags                    = local.tags
  active_services         = local.active_services
  
  alert_rule_identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.monitoring_umi.principal_id] # umi-prd-ManagementMonitoring-01 (Object ID)
  }

  email_receivers = [
    {
      name          = "ITTeam"
      email_address = "it@business.com"
    }
  ]
}
