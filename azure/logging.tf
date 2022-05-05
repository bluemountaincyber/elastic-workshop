resource "azurerm_eventhub_namespace" "elastic_namespace" {
  name                = "ElasticEventHubNamespace"
  location            = azurerm_resource_group.el_rg.location
  resource_group_name = azurerm_resource_group.el_rg.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "elastic_hub" {
  name                = "ElasticEventHub"
  namespace_name      = azurerm_eventhub_namespace.elastic_namespace.name
  resource_group_name = azurerm_resource_group.el_rg.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "auth_rule" {
  name                = "elastic-auth"
  namespace_name      = azurerm_eventhub_namespace.elastic_namespace.name
  resource_group_name = azurerm_resource_group.el_rg.name

  listen = true
  send   = true
  manage = false
}

resource "azurerm_eventhub_authorization_rule" "auth_rule" {
  name                = "elastic-auth"
  namespace_name      = azurerm_eventhub_namespace.elastic_namespace.name
  eventhub_name       = azurerm_eventhub.elastic_hub.name
  resource_group_name = azurerm_resource_group.el_rg.name
  listen              = true
  send                = true
  manage              = false
}

resource "azurerm_eventhub_consumer_group" "logstash" {
  name                = "logstash"
  namespace_name      = azurerm_eventhub_namespace.elastic_namespace.name
  eventhub_name       = azurerm_eventhub.elastic_hub.name
  resource_group_name = azurerm_resource_group.el_rg.name
}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                           = "el-activitylog"
  target_resource_id             = data.azurerm_subscription.current.id
  eventhub_name                  = azurerm_eventhub.elastic_hub.name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.auth_rule.id

  log {
    category = "Administrative"
    retention_policy {
      enabled = true
      days    = 1
    }
  }

  log {
    category = "Security"
    retention_policy {
      enabled = true
      days    = 1
    }
  }

  log {
    category = "Alert"
    retention_policy {
      enabled = true
      days    = 1
    }
  }
}