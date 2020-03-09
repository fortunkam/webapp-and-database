data "azurerm_client_config" "current" {
}
resource "azurerm_key_vault" "keyvault" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.service_principal_object_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
      "set",
      "list",
      "delete"
    ]

    storage_permissions = [
      "get",
    ]
  }

}

resource "azurerm_key_vault_secret" "sqlconnectionstring" {
  name         = "SQLConnectionString"
  value        = local.sql_connection_string
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "appInsightsKey" {
  name         = "AppInsightsInstumentationKey"
  value        = azurerm_application_insights.appinsights.instrumentation_key
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "appInsightsConnectionString" {
  name         = "AppInsightsConnectionString"
  value        = "InstrumentationKey=${azurerm_application_insights.appinsights.instrumentation_key}"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_access_policy" "websiteManaged" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = azurerm_app_service.website.identity[0].tenant_id
  object_id = azurerm_app_service.website.identity[0].principal_id

  secret_permissions = [
    "get",
  ]
}

