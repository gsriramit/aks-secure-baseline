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

# Step 2
# Create the TLS Certificates needed for the deployment of App-Gw and Traefik Ingress Controller

# execute the following commands from the context of the root folder
echo "Creating the TLS certificates"

export DOMAIN_NAME_AKS_BASELINE="contoso.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out appgw.crt -keyout appgw.key -subj "/CN=bicycle.${DOMAIN_NAME_AKS_BASELINE}/O=Contoso Bicycle" -addext "subjectAltName = DNS:bicycle.${DOMAIN_NAME_AKS_BASELINE}" -addext "keyUsage = digitalSignature" -addext "extendedKeyUsage = serverAuth"
openssl pkcs12 -export -out appgw.pfx -in appgw.crt -inkey appgw.key -passout pass:

export APP_GATEWAY_LISTENER_CERTIFICATE_AKS_BASELINE=$(cat appgw.pfx | base64 | tr -d '\n')

echo $APP_GATEWAY_LISTENER_CERTIFICATE_AKS_BASELINE

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out traefik-ingress-internal-aks-ingress-tls.crt -keyout traefik-ingress-internal-aks-ingress-tls.key -subj "/CN=*.aks-ingress.${DOMAIN_NAME_AKS_BASELINE}/O=Contoso AKS Ingress"

export AKS_INGRESS_CONTROLLER_CERTIFICATE_BASE64_AKS_BASELINE=$(cat traefik-ingress-internal-aks-ingress-tls.crt | base64 | tr -d '\n')

echo $AKS_INGRESS_CONTROLLER_CERTIFICATE_BASE64_AKS_BASELINE

echo "Completed Creating & Exporting the TLS certificates"


# Step 3
# This step is supposed to take care of the integration of the AKS with Azure AD

echo "Assigning members to the AAD groups"
export TENANTID_AZURERBAC_AKS_BASELINE=$(az account show --query tenantId -o tsv)

# the following statement has been commented as this deployment assumes the use of one Azure AD tenant for integration and RBAC 
#az login -t <Replace-With-ClusterApi-AzureAD-TenantId> --allow-no-subscriptions
export TENANTID_K8SRBAC_AKS_BASELINE=$(az account show --query tenantId -o tsv)

# Create the Cluster Admin AAD group and export the object Id for future use. 
export AADOBJECTID_GROUP_CLUSTERADMIN_AKS_BASELINE= $(az ad group create --display-name 'cluster-admins-bu0001a000800' --mail-nickname 'cluster-admins-bu0001a000800' --description "Principals in this group are cluster admins in the bu0001a000800 cluster." --force false --query objectId -o tsv)

# Create a "break-glass" cluster administrator user for your AKS cluster.
TENANTDOMAIN_K8SRBAC=$(az ad signed-in-user show --query 'userPrincipalName' -o tsv | cut -d '@' -f 2 | sed 's/\"//')
AADOBJECTNAME_USER_CLUSTERADMIN=bu0001a000800-admin
AADOBJECTID_USER_CLUSTERADMIN=$(az ad user create --display-name=${AADOBJECTNAME_USER_CLUSTERADMIN} --user-principal-name ${AADOBJECTNAME_USER_CLUSTERADMIN}@${TENANTDOMAIN_K8SRBAC} --force-change-password-next-login --password ChangeMebu0001a0008AdminChangeMe --query objectId -o tsv)

# Add the cluster admin user(s) to the cluster admin security group.
az ad group member add -g $AADOBJECTID_GROUP_CLUSTERADMIN_AKS_BASELINE --member-id $AADOBJECTID_USER_CLUSTERADMIN

# Create/identify the Azure AD security group that is going to be a namespace reader.
export AADOBJECTID_GROUP_A0008_READER_AKS_BASELINE=$(az ad group create --display-name 'cluster-ns-a0008-readers-bu0001a000800' --mail-nickname 'cluster-ns-a0008-readers-bu0001a000800' --description "Principals in this group are readers of namespace a0008 in the bu0001a000800 cluster." --force false --query objectId -o tsv)