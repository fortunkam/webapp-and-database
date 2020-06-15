provider "azurerm" {
  version         = "~>2.13"
  features {}
#   subscription_id = var.azure_subscription_id
#   client_id       = var.azure_subscription_client_id
#   client_secret   = var.azure_subscription_client_secret
#   tenant_id       = var.azure_tenant_id
}
# terraform {
#  backend "azurerm" {
#    }
# }
provider "random" {
  version = "~> 2.2"
}
resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.location
}
resource "random_password" "sql_password" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }
  length = 16
  special = true
  override_special = "_%@"
}


