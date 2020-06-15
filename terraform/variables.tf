# variable "azure_subscription_id" {}
# variable "azure_subscription_client_id" {}
# variable "azure_subscription_client_secret" {}
# variable "azure_tenant_id" {}
variable resource_group_name {
    default="web-tf-demo"
}
variable location {
    default="uksouth"
}
variable prefix {
    default="webmf01"
}
locals  {
    storage_name="${var.prefix}storage"
    app_plan_name="${var.prefix}-plan"
    web_site_name="${var.prefix}-site"
    sql_server_name="${var.prefix}-sql"
    elastic_pool_name="${var.prefix}-pool"
    database_name="${var.prefix}-db1"
    key_vault_name="${var.prefix}kv"
    cdn_profile_name="${var.prefix}-cdn"
    cdn_endpoint_name="${var.prefix}-end"
    app_insights_name="${var.prefix}-insights"
    sql_connection_string="Data Source=${local.sql_server_name}.database.windows.net;Initial Catalog=${local.database_name};User Id=${var.sql_username};Password=${random_password.sql_password.result};"

}
variable sql_username {
    default="SQLADMIN"
}

