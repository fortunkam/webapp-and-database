resource "azurerm_app_service_plan" "appplan" {
  name                = local.app_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "website" {
  name                = local.web_site_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appplan.id

  site_config {
    dotnet_framework_version = "v4.0"
  }

  identity {
      type          = "SystemAssigned"   
  }

  app_settings = {
    "WEBSITE_DISABLE_OVERLAPPED_RECYCLING" = "1"
     "APPLICATIONINSIGHTS_CONNECTION_STRING"="@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.appInsightsConnectionString.id})"
    "APPINSIGHTS_INSTRUMENTATIONKEY"="@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.appInsightsKey.id})"
    "APPINSIGHTS_PROFILERFEATURE_VERSION"="1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"="1.0.0"
    "ApplicationInsightsAgent_EXTENSION_VERSION"="~2"
    "DiagnosticServices_EXTENSION_VERSION"="~3"
    "InstrumentationEngine_EXTENSION_VERSION"="disabled"
    "SnapshotDebugger_EXTENSION_VERSION"="disabled"
    "XDT_MicrosoftApplicationInsights_BaseExtensions"="disabled"
    "XDT_MicrosoftApplicationInsights_Mode"="recommended"
  }

  connection_string {
      name="temp_umbracoDbDSN"
      type="SQLServer"
      value="@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sqlconnectionstring.id})"
  }
}

output "outbound_ips" {
    value = azurerm_app_service.website.outbound_ip_addresses
}

resource "azurerm_template_deployment" "webapp" {
  name                = local.web_site_name
  resource_group_name = azurerm_resource_group.rg.name
  template_body       = file("${path.module}/appSettings.json")

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "siteName"                              = local.web_site_name
    "location"                               = azurerm_resource_group.rg.location
  }

  deployment_mode = "Incremental"

  depends_on = [azurerm_app_service.website]
}
