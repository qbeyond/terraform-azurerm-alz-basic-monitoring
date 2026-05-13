data "azurerm_subscription" "current" {
}

resource "azurerm_monitor_action_group" "eventnotification" {
  name                = "EventEmailNotification"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "monitoremail"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each            = local.all_alertrules
  name                = each.key
  display_name        = lookup(each.value, "display_name", null)
  location            = var.log_analytics_workspace.location
  resource_group_name = var.log_analytics_workspace.resource_group_name
  tags                = var.tags

  scopes                = [var.log_analytics_workspace.id]
  description           = each.value.description
  enabled               = lookup(each.value, "enabled", true)
  severity              = lookup(each.value, "severity", 0)
  skip_query_validation = lookup(each.value, "skip_query_validation", true)
  evaluation_frequency  = each.value.frequency
  window_duration       = each.value.time_window
  
  # Advanced options
  query_time_range_override         = lookup(each.value, "query_time_range_override", null)
  mute_actions_after_alert_duration = lookup(each.value, "mute_actions_after_alert_duration", null)

  action {
    action_groups = [azurerm_monitor_action_group.eventnotification.id]
  }

  # Alert logic
  criteria {
    query = templatefile(each.value.query_path, {
      "all_events" = local.selected_events
    })
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    # Advanced options
    dynamic "failing_periods" {
      for_each = contains(keys(each.value), "include_failing_periods") && each.value.include_failing_periods != null ? [each.value.include_failing_periods] : []
      content {
        # Number of violations
        minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
        # Evaluation period
        number_of_evaluation_periods = failing_periods.value.number_of_evaluation_periods
      }
    }

    # Split by dimensions
    resource_id_column = "ResourceId"
  }

  dynamic "identity" {
    for_each = try(each.value.identity, null) != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = lower(identity.value.type) == "userassigned" ? try(identity.value.identity_ids, []) :   null
    }
  }

  target_resource_types = lookup(each.value, "target_resource_types",[
    "microsoft.compute/virtualmachines",
    "microsoft.hybridcompute/machines",
    "microsoft.compute/virtualmachinescalesets"
  ])
}
