#!/bin/bash
RG=umbraco-demo
LOC=uksouth
PREFIX=umbmf
STORAGENAME=$(echo $PREFIX)storage
STORAGECONTAINER=media
APPPLAN=$(echo $PREFIX)-appplan
WEBSITE=$(echo $PREFIX)-site
SQLSERVER=$(echo $PREFIX)-sql
ELASTICPOOLNAME=$(echo $PREFIX)-pool
DATABASE=$(echo $PREFIX)-db1
KEYVAULT=$(echo $PREFIX)kv
CDNPROFILE=$(echo $PREFIX)-cdn
CDNENDPOINT=$(echo $CDNPROFILE)-end
APPINSIGHTS=$(echo $PREFIX)-insights
CDNENDPOINT_ORIGIN="$STORAGENAME.blob.core.windows.net"

SQLUID=SQLADMIN
read -p 'SQL Master Password' SQLPWD



#Create the resource group
az group create --name $RG --location $LOC 

#Create the storage account 
az storage account create -n $STORAGENAME -g $RG --https-only 

STORAGEKEY=$(az storage account keys list -g $RG -n $STORAGENAME --query "[?keyName=='key1'].value" --output tsv)

#Create a blob container
az storage container create -n $STORAGECONTAINER --account-name $STORAGENAME --public-access blob --account-key $STORAGEKEY

#upload a sample image
az storage blob upload \
    -f ./AzureLogo.png   \
    -c $STORAGECONTAINER \
    -n "AzureLogo.png" \
    --account-name $STORAGENAME \
    --account-key $STORAGEKEY

#Create a CDN profile
az cdn profile create -n $CDNPROFILE -g $RG --sku Standard_Akamai --location "northeurope"

#Create a cdn endpoint
az cdn endpoint create -n $CDNENDPOINT -g $RG --profile-name $CDNPROFILE --origin $CDNENDPOINT_ORIGIN --origin-host-header $CDNENDPOINT_ORIGIN --enable-compression --location "northeurope"

#Create a keyvault 
az keyvault create -n $KEYVAULT -g $RG 

#Create the app plan 
az appservice plan create -n $APPPLAN -g $RG --sku S1

#Create the web app on the plan
az webapp create -n $WEBSITE --plan $APPPLAN -g $RG

#Create a database server
az sql server create --admin-password $SQLPWD --admin-user $SQLUID --name $SQLSERVER -g $RG

#Create an elastic pool 
az sql elastic-pool create -g $RG -s $SQLSERVER -n $ELASTICPOOLNAME --edition Standard 

#Create a database in the pool
az sql db create --name $DATABASE -g $RG --server $SQLSERVER --elastic-pool $ELASTICPOOLNAME

#Get the outbound addresses for the app service
OUTIP=$(az webapp show --resource-group $RG --name $WEBSITE --query outboundIpAddresses --output tsv)
for i in $(echo $OUTIP | sed "s/,/ /g")
do
   az sql server firewall-rule create -g $RG -s $SQLSERVER -n "ALLOW WEBAPP $i" --start-ip-address $i --end-ip-address $i 
done



#Get the connection string
# SQLCONNECTIONSTRING=$(az sql db show-connection-string --client ado.net --auth-type SqlPassword -s $SQLSERVER -n $DATABASE)
# SQLCONNECTIONSTRING=${SQLCONNECTIONSTRING//<username>/$SQLUID}
# SQLCONNECTIONSTRING=${SQLCONNECTIONSTRING//<password>/$SQLPWD}
SQLCONNECTIONSTRING="Data Source=$SQLSERVER.database.windows.net;Initial Catalog=$DATABASE;User Id=$SQLUID;Password=$SQLPWD;"

#Add the connection string to key vault
az keyvault secret set --name SqlConnectionString --vault-name $KEYVAULT --value "$SQLCONNECTIONSTRING"

#Add a managed identity to the web app
az webapp identity assign -g $RG -n $WEBSITE

WEBSITEPRINCIPALID=$(az webapp identity show --name $WEBSITE -g $RG --query 'principalId' -o tsv)

#Add permissions so the web app can access keyvault
az keyvault set-policy --name $KEYVAULT --secret-permissions get --object-id $WEBSITEPRINCIPALID

#Get the keyvault secret version 
SECRETREFERENCE=$(az keyvault secret show --vault-name $KEYVAULT --name SqlConnectionString --query id -o tsv)

#Add the key vault reference to the webapp connection string
az webapp config connection-string set -g $RG -n $WEBSITE -t SQLServer \
    --settings umbracoDbDSN="@Microsoft.KeyVault(SecretUri=$SECRETREFERENCE)"

#Add the recommended setting
az webapp config appsettings set -g $RG -n $WEBSITE --settings WEBSITE_DISABLE_OVERLAPPED_RECYCLING=1

#Add app insights
az extension add --name application-insights
az monitor app-insights component create --app $APPINSIGHTS --kind web -g $RG --application-type web

AIKEY=$(az monitor app-insights component show --app $APPINSIGHTS -g $RG --query instrumentationKey -o tsv)
#Add the connection string to key vault
az keyvault secret set --name AppInsightsInstumentationKey --vault-name $KEYVAULT --value "$AIKEY"
KEYREFERENCE=$(az keyvault secret show --vault-name $KEYVAULT --name AppInsightsInstumentationKey --query id -o tsv)

az keyvault secret set --name AppInsightsConnectionString --vault-name $KEYVAULT --value "InstrumentationKey=$AIKEY"
CONNSTRREF=$(az keyvault secret show --vault-name $KEYVAULT --name AppInsightsConnectionString --query id -o tsv)

az webapp config appsettings set -g $RG -n $WEBSITE \
    --settings APPLICATIONINSIGHTS_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=$CONNSTRREF)" \
    --slot-settings APPINSIGHTS_INSTRUMENTATIONKEY="@Microsoft.KeyVault(SecretUri=$KEYREFERENCE)" \
                    APPINSIGHTS_PROFILERFEATURE_VERSION=1.0.0 \
                    APPINSIGHTS_SNAPSHOTFEATURE_VERSION=1.0.0 \
                    ApplicationInsightsAgent_EXTENSION_VERSION=~2 \
                    DiagnosticServices_EXTENSION_VERSION=~3 \
                    InstrumentationEngine_EXTENSION_VERSION=disabled \
                    SnapshotDebugger_EXTENSION_VERSION=disabled \
                    XDT_MicrosoftApplicationInsights_BaseExtensions=disabled \
                    XDT_MicrosoftApplicationInsights_Mode=recommended


