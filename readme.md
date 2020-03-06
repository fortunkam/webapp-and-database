# Simple script to configure an app service and datasbe for an Umbraco 7 empty install 

- Azure App Service with Managed Identity
- SQL Server + database with firewall rules to lock down DB to self and web app only
- Key Vault populated with SQL Server and App Insights connection string (and secret read persmissions granted to App Service)
- App Service settings for App Insights and Umbraco connection string (using KeyVault references)
- Storage account and CDN (not used yet but the theory is the Umbraco media library would be served from here)
