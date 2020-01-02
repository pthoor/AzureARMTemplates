# Azure Policy \ VM SKU and Location Policy

Uses three built-in Azure Policy Definitions into one Initiative and assigned to Subscription level.
Deploy to Azure button won't work. Will be fixed in future.

BuiltIn definitions used for this Initiative:
- Allowed locations for resource groups
- Allowed locations
- Allowed virtual machine SKUs

To deploy:
New-AzDeployment -Name "VMSKUandLocationPolicy" -Location "westeurope" -TemplateUri "https://raw.githubusercontent.com/pthoor/AzureARMTemplates/master/Azure%20Policy/VM%20SKU%20and%20Location%20Policy/azurepolicy.json"

(The parameter Location in New-AzDeployment are just for storing deployment metadata)

Change location and VM SKU after your needs!

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpthoor%2FAzureARMTemplates%2Fmaster%2FAzure%20Policy%2FVM%20SKU%20and%20Location%20Policy%2Fazurepolicy.json" alt="Deploy to Azure" target="_blank">
   <img src="http://azuredeploy.net/deploybutton.png"/>
</a>