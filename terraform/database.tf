resource "azurerm_sql_server" "sql" {
  name                         = local.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  administrator_login          = var.sql_username
  administrator_login_password = random_password.sql_password.result
  version                      = "12.0"
}

resource "azurerm_sql_elasticpool" "sqlpool" {
  name                = local.elastic_pool_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sql.name
  edition             = "Standard"
  dtu                 = 100
}

resource "azurerm_sql_database" "db" {
  name                = local.database_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sql.name
  elastic_pool_name   = azurerm_sql_elasticpool.sqlpool.name
}

resource "azurerm_sql_firewall_rule" "rules" {
  for_each            = toset(split(",",azurerm_app_service.website.outbound_ip_addresses))
  name                = "Allow WebSite ${each.value}"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sql.name
  start_ip_address    = each.value
  end_ip_address      = each.value
  
  depends_on = [azurerm_app_service.website]
}

output "dbconnectionstring" {
  value = local.sql_connection_string
} 