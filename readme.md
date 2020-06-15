# Simple script to configure an app service and database for an Umbraco 7 empty install 

- Azure App Service with Managed Identity
- SQL Server + database with firewall rules to lock down DB to self and web app only
- Key Vault populated with SQL Server and App Insights connection string (and secret read persmissions granted to App Service)
- App Service settings for App Insights and Umbraco connection string (using KeyVault references)
- Storage account and CDN (not used yet but the theory is the Umbraco media library would be served from here)


## UPDATE - Now with Terraform script (as an alternative to the CLI script)
TODO: The script doesn't contain the blob storage container or CDN yet.
The script uses an ARM template to setup the slot settings (and has a commented out block for access restrictions (untested!)), these resources are not controlled by terraform!
I have excluded the backend support for now.

On first install you may get a failure related to the outbound_ip_addresses on the sql firewall.  Comment out this resource, run terraform apply, uncomment the resource, run terraform apply again.  (This uses a foreach loop to add firewall rules but because the resource doesn't exist on first run it can't work out what state it needs to manage)

The following command can be used to deploy an umbraco site from github

    az webapp deployment source config --branch master --manual-integration --name "webmf01-site" --repo-url "https://github.com/fortunkam/umbraco-starter" --resource-group "web-tf-demo"

(Substitute your values)

Run the website after deploy and the umbraco setup will begin, make sure you customize the install to select Azure SQL.

**CAVEAT** This is for demo purposes only, in production you don't want to be using the master credentials (SQL username and password) in your web app. 
