locals {
  path = "${path.module}/queries"

  default_queries = merge({
    "alr-prd-Heartbeat-ux-law-metric-crit-01" : {
      description                       = "Alert when Heartbeat of Unix machines Stopped"
      query_path                        = "${local.path}/unix_heartbeat.kusto"
      time_window                       = "P2D"
      frequency                         = "PT5M"
      query_time_range_override         = "P2D"
      mute_actions_after_alert_duration = "P1D"
    }
    "alr-prd-Diskspace-ux-law-metric-warn-crit-01" : {
      description                       = "Alert when filesystem of Unix runs out of space"
      query_path                        = "${local.path}/unix_filespace.kusto"
      time_window                       = "P2D"
      frequency                         = "PT5M"
      query_time_range_override         = "P2D"
      mute_actions_after_alert_duration = "P1D"
    }
    "alr-prd-Heartbeat-win-law-metric-crit-01" : {
      description                       = "Alert when Heartbeat from Windows machines Stopped"
      query_path                        = "${local.path}/windows_heartbeat.kusto"
      time_window                       = "P2D"
      frequency                         = "PT5M"
      query_time_range_override         = "P2D"
      mute_actions_after_alert_duration = "P1D"
    }
    "alr-prd-Diskspace-win-law-metric-warn-crit-01" : {
      description                       = "Alert when filesystem of Windows runs out of space"
      query_path                        = "${local.path}/windows_filespace.kusto"
      time_window                       = "P2D"
      frequency                         = "PT5M"
      query_time_range_override         = "P2D"
      mute_actions_after_alert_duration = "P1D"
    }
  })

  empty_query_object = {
    query_path                = null
    description               = null
    time_window               = "P2D"
    frequency                 = "PT5M"
    non_productive            = false
    display_name              = null
    query_time_range_override = null
    enabled                   = true
    severity                  = 0
    skip_query_validation     = true
    target_resource_types     = [
      "microsoft.compute/virtualmachines",
      "microsoft.hybridcompute/machines",
      "microsoft.compute/virtualmachinescalesets"
    ]
    include_failing_periods = null
    identity                = var.alert_rule_identity
  }

  rules = {     
    for key in setunion(keys(local.default_queries), keys(var.additional_queries)) :     
      key => merge(
        local.empty_query_object,       
        lookup(local.default_queries, key, {}), # use defaults if present       
        { for k, v in try(var.additional_queries[key], {}) : k => v if v != null } # apply overrides (empty map when missing)
      )
  }

  event_rule = {
    "alr-prd-Eventlog-win-law-logsea-crit-warn-01" : {
      description                       = "Alert when the Windows event was logged"
      query_path                        = "${local.path}/windows_event.kusto.tftpl"
      time_window                       = "PT30M"
      frequency                         = "PT5M"
      query_time_range_override         = "P1D"
      mute_actions_after_alert_duration = "PT2H"
    }
  }

  all_alertrules = merge(
    local.rules,
    length(local.selected_events) > 0 ? local.event_rule : {}
  )

}
