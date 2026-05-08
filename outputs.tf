output "action_group_id" {
  value       = azurerm_monitor_action_group.eventnotification.id
  description = "The id of the action group created for the event pipeline."
}

output "windows_dcr_ids" {
  value = [
    azurerm_monitor_data_collection_rule.event_log.id
  ]
  description = "Map of DCRs and their resource IDs that should be associated to windows VMs."
}

output "linux_dcr_ids" {
  value = [
    azurerm_monitor_data_collection_rule.syslog.id
  ]
  description = "Map of DCRs and their resource IDs that should be associated to linux VMs."
}

output "vminsights_dcr_id" {
  value       = azurerm_monitor_data_collection_rule.vm_insight.id
  description = "Resource ID of the VM-Insights DCR that should be associated with every VM."
}

output "alert_rules_for_role_assignments" {
  description = "Alert rules keyed by statically known names with their principal IDs."
  value = (
    var.alert_rule_identity != null &&
    lower(var.alert_rule_identity.type) == "systemassigned"
  ) ? {
    for rule_name in keys(local.all_alertrules) :
    rule_name => {
      principal_id = azurerm_monitor_scheduled_query_rules_alert_v2.this[rule_name].identity[0].principal_id
    }
  } : {}
}
