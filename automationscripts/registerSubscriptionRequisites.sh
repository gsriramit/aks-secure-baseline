#!/bin/bash

# Step 1.2
# Register the preview features for the target subscription
az feature register --namespace "Microsoft.ContainerService" -n "AKS-AzureKeyVaultSecretsProvider"
az feature register --namespace "Microsoft.ContainerService" -n "EventgridPreview"
az feature register --namespace "Microsoft.ContainerService" -n "DisableLocalAccountsPreview"
az feature register --namespace "Microsoft.ContainerService" -n "EnablePodIdentityPreview"

# Keep running until all three say "Registered." (This may take up to 20 minutes.)
az feature list -o table --query "[?name=='Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider' || name=='Microsoft.ContainerService/EventgridPreview' || name=='Microsoft.ContainerService/DisableLocalAccountsPreview' || name =='Microsoft.ContainerService/EnablePodIdentityPreview'].{Name:name,State:properties.state}"

# When all say "Registered" then re-register the AKS resource provider (To-Do- check for a subscription that does not have the features registered)
az provider register --namespace Microsoft.ContainerService

echo "Completed registering the necessary features"
