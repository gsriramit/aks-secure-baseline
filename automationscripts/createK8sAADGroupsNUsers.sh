#!/bin/bash

# Step 3
# This step is supposed to take care of the integration of the AKS with Azure AD

echo "Assigning members to the AAD groups"
export TENANTID_AZURERBAC_AKS_BASELINE=$(az account show --query tenantId -o tsv)

# the following statement has been commented as this deployment assumes the use of one Azure AD tenant for integration and RBAC 
#az login -t <Replace-With-ClusterApi-AzureAD-TenantId> --allow-no-subscriptions
export TENANTID_K8SRBAC_AKS_BASELINE=$(az account show --query tenantId -o tsv)

# Create the Cluster Admin AAD group and export the object Id for future use. 
export AADOBJECTID_GROUP_CLUSTERADMIN_AKS_BASELINE=$(az ad group create --display-name 'cluster-admins-bu0001a000800' --mail-nickname 'cluster-admins-bu0001a000800' --description "Principals in this group are cluster admins in the bu0001a000800 cluster." --force false --query objectId -o tsv)

# Create a "break-glass" cluster administrator user for your AKS cluster.
#object-id of any domain user- this will be used to fetch the domain suffix
domainuserObjectId='d5d5599b-0ddd-46b0-9d54-8f0a04f4b5e6'
TENANTDOMAIN_K8SRBAC=$(az ad user show --id  $domainuserObjectId --query 'userPrincipalName' -o tsv | cut -d '@' -f 2 | sed 's/\"//')
AADOBJECTNAME_USER_CLUSTERADMIN=bu0001a000800-admin
AADOBJECTID_USER_CLUSTERADMIN=$(az ad user create --display-name=${AADOBJECTNAME_USER_CLUSTERADMIN} --user-principal-name ${AADOBJECTNAME_USER_CLUSTERADMIN}@${TENANTDOMAIN_K8SRBAC} --force-change-password-next-login --password ChangeMebu0001a0008AdminChangeMe --query objectId -o tsv)

# Add the cluster admin user(s) to the cluster admin security group.
az ad group member add -g $AADOBJECTID_GROUP_CLUSTERADMIN_AKS_BASELINE --member-id $AADOBJECTID_USER_CLUSTERADMIN

# Create/identify the Azure AD security group that is going to be a namespace reader.
export AADOBJECTID_GROUP_A0008_READER_AKS_BASELINE=$(az ad group create --display-name 'cluster-ns-a0008-readers-bu0001a000800' --mail-nickname 'cluster-ns-a0008-readers-bu0001a000800' --description "Principals in this group are readers of namespace a0008 in the bu0001a000800 cluster." --force false --query objectId -o tsv)


#Update the objectId values in the prod config

echo "Updating Authorization Tenant-Id in the prod config"
echo $(cat azuredeploy.parameters.prod.json | jq --arg authz_tenant_Id "$TENANTID_K8SRBAC_AKS_BASELINE" '.parameters.k8sControlPlaneAuthorizationTenantId.value|=$authz_tenant_Id') > azuredeploy.parameters.prod.json
echo "Updating CLusterAdminGroup-Object-Id in the prod config"
echo $(cat azuredeploy.parameters.prod.json | jq --arg cluster_admin_objectId "$AADOBJECTID_GROUP_CLUSTERADMIN_AKS_BASELINE" '.parameters.clusterAdminAadGroupObjectId.value|=$cluster_admin_objectId') > azuredeploy.parameters.prod.json
echo "Updating NamespacereaderGroup-Object-Id in the prod config"
echo $(cat azuredeploy.parameters.prod.json | jq --arg namespace_reader_objectId "$AADOBJECTID_GROUP_A0008_READER_AKS_BASELINE" '.parameters.a0008NamespaceReaderAadGroupObjectId.value|=$namespace_reader_objectId') > azuredeploy.parameters.prod.json

# Completed updating the parameters file with the necessary config
echo $(cat azuredeploy.parameters.prod.json)
