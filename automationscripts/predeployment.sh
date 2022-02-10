#!/bin/bash

# Step 1.1
# Create the Service Principal that will be used to trigger the workflows and assign it the appropriate AAD and Azure RBAC roles
# Create an Azure Service Principal - this statement should be run from the azure bash shell or the Ubuntu WSL and the output JSON needs to be saved to the GitHub secrets called "Azure_Credentials"
az ad sp create-for-rbac --name "github-workflow-aks-cluster" --skip-assignment

#get the objectId of the SP
SP_OBJECTID=$(az ad sp list --display-name 'github-workflow-aks-cluster' --query [0].objectId)

# replace the value of the --id parameter in the following command with the objectId of the newly created service principal
export APP_ID=$(az ad sp show --id $SP_OBJECTID --query appId -o tsv)

# Wait for propagation
until az ad sp show --id ${APP_ID} &> /dev/null ; do echo "Waiting for Azure AD propagation" && sleep 5; done

# Assign built-in Contributor RBAC role for creating resource groups and performing deployments at subscription level
az role assignment create --assignee $APP_ID --role 'Contributor'

# Assign built-in User Access Administrator RBAC role since granting RBAC access to other resources during the cluster creation will be required at subscription level (e.g. AKS-managed Internal Load Balancer, ACR, Managed Identities, etc.)
az role assignment create --assignee $APP_ID --role 'User Access Administrator'

echo "Completed assigning the necessary permissions to the SP"


#PS /home/sriram> Get-AzureADDirectoryRole -ObjectId 573c8812-a1e9-4966-9ae7-a64eb08a3637
#ObjectId                             DisplayName        Description
#--------                             -----------        -----------
#573c8812-a1e9-4966-9ae7-a64eb08a3637 User Administrator Can manage all aspects of users and groups, including resetting passwords for limited admins.

#Powershell command to assign the github-workflow service principal the User Administrator role- this is needed to be able to create the AAD groups and the BreakGlass Account
#References
#https://docs.microsoft.com/en-us/powershell/module/azuread/add-azureaddirectoryrolemember?view=azureadps-2.0
#https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureaddirectoryrole?view=azureadps-2.0

# Important Note: Execute this statement from the a PS session to assign the necessary AAD role to the SP
#Add-AzureADDirectoryRoleMember -ObjectId 573c8812-a1e9-4966-9ae7-a64eb08a3637 -RefObjectId a2855bef-2150-4983-8b1b-6d6d2bcc52f0

# A) Apply the RBAC at the subscription or the RG level
# B) for this execution "Key Vault Certificates Officer" role should be sufficient
az role assignment create --role a4417e6f-fecd-4de8-b567-7b0420556985 --assignee-principal-type ServicePrincipal --assignee-object-id $SP_OBJECTID --subscription "{subscriptionNameOrId}"

#Use the following assignment syntax if assigning the role at the RG level instead of the subscription
#--scope '/subscriptions/<subscriptionId>/resourceGroups/rg-bu0001a0008/providers/Microsoft.KeyVault/vaults/kv-aks-4vgqts35oun5k'
