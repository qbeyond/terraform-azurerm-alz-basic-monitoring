variable "log_analytics_workspace" {
  type = object({
    id                  = string
    name                = string
    resource_group_name = string
    location            = string
    workspace_id        = string
  })
  nullable    = false
  description = <<-DOC
  ```
  Log Analytics Worksapce that all VMs are connected to for monitoring.
  {
    id                  = ID of the Log Analytics Workspace.
    name                = Name of the Log Analytics Workspace.
    resource_group_name = Resource group name of the Log Analytics Workspace.
    location            = Location of the Log Analytics Workspace.
    workspace_id        = Workspace ID of the Log Analytics Workspace.
  }
  ```
  DOC
}

variable "additional_queries" {
  type = map(object({
    query_path                        = optional(string)
    description                       = optional(string)
    time_window                       = optional(string)
    frequency                         = optional(string)
    non_productive                    = optional(bool, false)
    display_name                      = optional(string)
    query_time_range_override         = optional(string)
    enabled                           = optional(bool)
    severity                          = optional(number)
    skip_query_validation             = optional(bool)
    target_resource_types             = optional(list(string))
    mute_actions_after_alert_duration = optional(string)
    include_failing_periods           = optional(object({
      minimum_failing_periods_to_trigger_alert = number
      number_of_evaluation_periods             = number
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }), null)
  }))

  validation {
    condition = alltrue([
      for key, val in var.additional_queries :
        contains(keys(local.default_queries), key) ||
        try(val.query_path, null) != null
    ])
    error_message = "Custom alert rules must include query_path."
  }

  default     = {}
  nullable    = false
  description = <<-DOC
  ```
  List of additional alert rule queries to create with a file path, description and time_window.
  {
    "query_path"                        = Path to the kusto query file.
    "description"                       = Description of the alert rule.
    "time_window"                       = Time window for the alert rule,                                e.g. "PT5M", "P1D",                           "P2D".
    "frequency"                         = Frequency of evaluation,                                       e.g. "PT5M", "PT15M".
    "non_productive"                    = If true,                                                       the alert will use the non productive action group.
    "display_name"                      = Optional display name for the alert rule. If not set,          the resource name will be used.
    "query_time_range_override"         = Optional time range override for the query,                    e.g. "P1D",  "P2D". If not set,               the time_window will be used.
    "enabled"                           = Optional If the rule is enabled. Default is true.
    "severity"                          = Optional Severity of the alert rule. Default is 0.
    "skip_query_validation"             = Optional If true,                                              the query validation will be skipped. Default is true.
    "target_resource_types"             = Optional List of resource types to target. If not set,         the default resource types will be used.
    "mute_actions_after_alert_duration" = Optional duration to mute actions after an alert is triggered, e.g. "PT1H", "P1D". Possible values are PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H, P1D and P2D.
    "include_failing_periods"           = Optional object to include failing periods in the alert rule.
      {
        minimum_failing_periods_to_trigger_alert = number of failing periods to trigger the alert.
        number_of_evaluation_periods             = number of evaluation periods to consider.
      }

    "identity"   = Optional object to include a managed identity in the additional query.
      {
        type = managed identity type (UserAssigned or SystemAssigned)
        identity_ids             = An optional list with the ids of the managed identity we want to associate.
      }
  }
  ```
  DOC
}

variable "tags" {
  type        = map(string)
  description = "Tags that will be assigned to all resources."
  default     = {}
}

variable "active_services" {
  type = object({
    active_directory = optional(bool, false)
    managed_os       = optional(bool, false)
    mssql            = optional(bool, false)
  })
  default     = {}
  description = <<-DOC
  ```
  Services to receive event monitoring.
  {
    active_directory = Enable monitoring for Azure AD.
    managed_os       = Enable monitoring for Managed OS.
    mssql            = Enable monitoring for Azure SQL and SQL on VMs.
  }
  ```
  DOC
}

variable "additional_data_collection_rules" {
  type = map(object({
    name        = string
    kind        = optional(string)
    description = optional(string)
    tags        = optional(map(string), {})

    destinations = object({
      azure_monitor_metrics = optional(object({ name = string }), null)
      event_hub             = optional(object({ name = string, event_hub_id = string }), null)
      event_hub_direct      = optional(object({ name = string, event_hub_id = string }), null)
      log_analytics         = optional(object({ name = string, workspace_resource_id = string }), null)
      monitor_account       = optional(object({ name = string, monitor_account_id = string }), null)
      storage_blob          = optional(object({ name = string, storage_account_id = string, container_name = string }), null)
      storage_blob_direct   = optional(object({ name = string, storage_account_id = string, container_name = string }), null)
      storage_table_direct  = optional(object({ name = string, storage_account_id = string, table_name = string }), null)
    })

    data_sources = optional(object({
      data_import = optional(object({
        event_hub_data_sources = object({
          name           = string
          stream         = string
          consumer_group = optional(string)
        })
      }), null)

      extension = optional(list(object({
        extension_name     = string
        name               = string
        streams            = list(string)
        extension_json     = optional(string)
        input_data_sources = optional(list(string))
      })), [])

      iis_log = optional(list(object({
        name            = string
        streams         = list(string)
        log_directories = optional(list(string))
      })), [])

      log_file = optional(list(object({
        name          = string
        streams       = list(string)
        file_patterns = list(string)
        format        = string
      })), [])

      performance_counter = optional(list(object({
        name                          = string
        streams                       = list(string)
        counter_specifiers            = list(string)
        sampling_frequency_in_seconds = number
      })), [])

      platform_telemetry = optional(list(object({
        name    = string
        streams = list(string)
      })), [])

      prometheus_forwarder = optional(list(object({
        name    = string
        streams = list(string)
      })), [])

      syslog = optional(list(object({
        name           = string
        streams        = list(string)
        facility_names = list(string)
        log_levels     = list(string)
      })), [])

      windows_event_log = optional(list(object({
        name           = string
        streams        = list(string)
        x_path_queries = list(string)
      })), [])

      windows_firewall_log = optional(list(object({
        name    = string
        streams = list(string)
      })), [])
    }), {})

    data_flow = list(object({
      streams            = list(string)
      destinations       = list(string)
      output_stream      = optional(string)
      built_in_transform = optional(string)
      transform_kql      = optional(string)
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }), null)
  }))

  default = {}

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        try(v.destinations.azure_monitor_metrics.name, "") != "" ||
        try(v.destinations.event_hub.name, "")             != "" ||
        try(v.destinations.event_hub_direct.name, "")      != "" ||
        try(v.destinations.log_analytics.name, "")         != "" ||
        try(v.destinations.monitor_account.name, "")       != "" ||
        try(v.destinations.storage_blob.name, "")          != "" ||
        try(v.destinations.storage_blob_direct.name, "")   != "" ||
        try(v.destinations.storage_table_direct.name, "")  != ""
      )
    ])
    error_message = "Each DCR must declare at least one destination."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      length(
        toset(compact(concat(
          [try(v.destinations.azure_monitor_metrics.name, null)],
          [try(v.destinations.event_hub.name, null)],
          [try(v.destinations.event_hub_direct.name, null)],
          [try(v.destinations.log_analytics.name, null)],
          [try(v.destinations.monitor_account.name, null)],
          [try(v.destinations.storage_blob.name, null)],
          [try(v.destinations.storage_blob_direct.name, null)],
          [try(v.destinations.storage_table_direct.name, null)]
        )))
      ) == length(
        compact(concat(
          [try(v.destinations.azure_monitor_metrics.name, null)],
          [try(v.destinations.event_hub.name, null)],
          [try(v.destinations.event_hub_direct.name, null)],
          [try(v.destinations.log_analytics.name, null)],
          [try(v.destinations.monitor_account.name, null)],
          [try(v.destinations.storage_blob.name, null)],
          [try(v.destinations.storage_blob_direct.name, null)],
          [try(v.destinations.storage_table_direct.name, null)]
        ))
      )
    ])
    error_message = "Destination 'name' values must be unique across all destination types in a DCR."
  }

  validation {
    condition     = alltrue([for _, v in var.additional_data_collection_rules : length(v.data_flow) > 0])
    error_message = "Each DCR must define at least one data_flow."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      alltrue([
        for df in v.data_flow: 
        contains(df.destinations, try(v.destinations.azure_monitor_metrics.name, "")) ?
          length(setsubtract(toset(df.streams), toset(["Microsoft-InsightsMetrics"]))) == 0
        :   true
      ])
    ])
    error_message = "When routing to 'azure_monitor_metrics', streams must be only 'Microsoft-InsightsMetrics'."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      contains(["linux", "windows", "agentdirecttostore", "workspacetransforms"], lower(v.kind))
    ])
    error_message = "kind must be one of: Linux, Windows, AgentDirectToStore, WorkspaceTransforms."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      lower(v.kind) != "linux" || length(try(v.data_sources.windows_event_log, [])) == 0
    ])
    error_message = "For kind 'Linux', 'windows_event_log' data sources are not allowed."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      lower(v.kind) != "windows" || length(try(v.data_sources.syslog, [])) == 0
    ])
    error_message = "For kind 'Windows', 'syslog' data sources are not allowed."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        !(
          try(v.destinations.event_hub_direct.name, "")     != "" ||
          try(v.destinations.storage_blob_direct.name, "")  != "" ||
          try(v.destinations.storage_table_direct.name, "") != ""
        )
      ) || lower(v.kind) == "agentdirecttostore"
    ])
    error_message = "event_hub_direct, storage_blob_direct and storage_table_direct are only allowed when kind = AgentDirectToStore."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules :
      v.identity == null || v.identity.type == null ? true :
      contains(["systemassigned","userassigned"], lower(v.identity.type))
    ])
    error_message = "identity.type must be 'SystemAssigned' or 'UserAssigned' when provided."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules :
      v.identity == null || v.identity.type == null ? true :
      (
        lower(v.identity.type) == "systemassigned" ? length(v.identity.identity_ids) == 0 :
        lower(v.identity.type) == "userassigned"  ? (length(v.identity.identity_ids) == 1
          && alltrue([for id in v.identity.identity_ids : length(trim(id)) > 0])) :
        false
      )
    ])
    error_message = "For UserAssigned provide exactly one non-empty identity_id; for SystemAssigned don't provide identity_ids."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        try(v.data_sources.data_import, null) == null
        || length(try(v.data_sources.data_import.event_hub_data_sources, [])) > 0
      )
    ])
    error_message = "When 'data_import' is set, it must include at least one 'event_hub_data_source'."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      alltrue([
        for      pc in try(v.data_sources.performance_counter, [])                                : 
        contains(pc.streams, "Microsoft-InsightsMetrics") ? pc.sampling_frequency_in_seconds == 60: true
      ])
    ])
    error_message = "performance_counter using 'Microsoft-InsightsMetrics' must set sampling_frequency_in_seconds = 60."
  }

  description = <<-DOC

  ```
  Additional data collection rules to create.
  {
    name        = Name of the data collection rule.
    kind        = Kind of the data collection rule. Possible values are "Linux" and "Windows". Default is "Linux".
    description = Description of the data collection rule.
    tags        = Tags to assign to the data collection rule.

    destinations = {
      azure_monitor_metrics = {
        name = Name of the Azure Monitor Metrics destination.
      }
      event_hub = {
        name         = Name of the Event Hub destination.
        event_hub_id = Resource ID of the Event Hub namespace.
      }
      event_hub_direct = {
        name         = Name of the Event Hub Direct destination.
        event_hub_id = Resource ID of the Event Hub namespace.
      }
      log_analytics = {
        name                  = Name of the Log Analytics destination.
        workspace_resource_id = Resource ID of the Log Analytics workspace.
      }
      monitor_account = {
        name               = Name of the Monitor Account destination.
        monitor_account_id = Resource ID of the Monitor Account.
      }
      storage_blob = {
        name               = Name of the Storage Blob destination.
        storage_account_id = Resource ID of the Storage Account.
        container_name     = Name of the Blob container.
      }
      storage_blob_direct = {
        name               = Name of the Storage Blob Direct destination.
        storage_account_id = Resource ID of the Storage Account.
        container_name     = Name of the Blob container.
      }
      storage_table_direct = {
        name               = Name of the Storage Table Direct destination.
        storage_account_id = Resource ID of the Storage Account.
        table_name         = Name of the Table.
      }
    }

    data_sources = {
      data_import = {
        event_hub_data_sources = [
          {
            name           = Name of the Event Hub data source.
            stream         = Stream to which data will be sent. E.g. "Microsoft-Event".
            consumer_group = Consumer group for the Event Hub.
          }
        ]
      }

      extension = [
        {
          extension_name = Name of the extension. E.g. "DependencyAgent".
          name           = Name of the data source.
          streams        = List of streams to which data will be sent. E.g. ["Microsoft-ServiceMap"].
        }
      ]

      iis_log = [
        {
          name            = Name of the IIS log data source.
          streams         = List of streams to which data will be sent. E.g. ["Microsoft-IISLog"].
          log_directories = List of directories where IIS logs are located.
        }
      ]
      log_file = [
        {
          name          = Name of the log file data source.
          streams       = List of streams to which data will be sent. E.g. ["Microsoft-WindowsEvent"].
          file_patterns = List of file patterns to include. E.g. ["/var/log/syslog*"].
          format        = Format of the log file. E.g. "Syslog", "JSON", "CEF".
        }
      ]

      performance_counter = [
        {
          name                          = Name of the performance counter data source.
          streams                       = List of streams to which data will be sent. E.g. ["Microsoft-InsightsMetrics"].
          counter_specifiers            = List of performance counter specifiers.
          sampling_frequency_in_seconds = Sampling frequency in seconds.
        }
      ]

      platform_telemetry = [
        {
          name    = Name of the platform telemetry data source.
          streams = List of streams to which data will be sent. E.g. ["Microsoft-PlatformTelemetry"].
        }
      ]

      prometheus_forwarder = [
        {
          name    = Name of the Prometheus forwarder data source.
          streams = List of streams to which data will be sent. E.g. ["Microsoft-PrometheusMetrics"].
        }
      ]

      syslog = [
        {
          name           = Name of the syslog data source.
          streams        = List of streams to which data will be sent. E.g. ["Microsoft-Syslog"].
          facility_names = List of facility names to include. E.g. ["auth", "cron"].
          log_levels     = List of log levels to include. E.g. ["emerg", "alert", "crit", "err"].
        }
      ]

      windows_event_log = [
        {
          name           = Name of the Windows event log data source.
          streams        = List of streams to which data will be sent. E.g. ["Microsoft-Event"].
          x_path_queries = List of XPath queries to filter events.
        }
      ]

      windows_firewall_log = [
        {
          name    = Name of the Windows firewall log data source.
          streams = List of streams to which data will be sent. E.g. ["Microsoft-WindowsFirewall"].
        }
      ]
    }

    data_flow = [
      {
        streams      = List of streams to route. E.g. ["Microsoft-Event"].
        destinations = List of destination names to which data will be sent.
        built_in_transform = Built-in transform to apply to the input stream.
        transform_kql = KQL query that transform the input stream. Used instead of "built_in_transform"
        output_stream = Name of the output stream after the transform.
      }
    ]

    identity = {
      type         = Type of managed identity. Possible values are "SystemAssigned", "UserAssigned" and "SystemAssigned, UserAssigned".
      identity_ids = List of user assigned identity IDs if type includes "UserAssigned".
    }
  }

  ```
  DOC
}

variable "email_receivers" {
  description = "Email recipient list for the Action Group. Each item must include a unique name and email address."
  type = list(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = optional(bool, true)
  }))
  default = []
}

variable "alert_rule_identity" {
  description = <<-DOC
  Managed Identity for the scheduled query alert rules.
  - type: "SystemAssigned" or "UserAssigned"
  - identity_ids: Azure resource IDs of User Assigned Identities. Required only when type is "UserAssigned".

  Set to null to deploy alert rules without a managed identity.
  DOC

  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })

  default = null

  validation {
    condition = var.alert_rule_identity == null || contains(
      ["SystemAssigned", "UserAssigned"],
      var.alert_rule_identity.type
    )
    error_message = "Identity type must be either 'SystemAssigned' or 'UserAssigned'."
  }

  validation {
    condition = var.alert_rule_identity == null ? true : (
      var.alert_rule_identity.type != "UserAssigned" ||
      length(var.alert_rule_identity.identity_ids) > 0
    )
    error_message = "When type is 'UserAssigned', identity_ids must contain at least one User Assigned Identity resource ID."
  }
}