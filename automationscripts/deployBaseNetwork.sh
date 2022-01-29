#!/bin/bash

# assign the commandline values to local variables for readability
hub_rg_location=$1 # location of the hub's resource group- does not have to be the same as the resources'
spoke_rg_location=$2 # location of the spoke's resource group- does not have to be the same as the resources'
resource_location=$3 # location of the actual resources deployed in the hub and spoke RGs
hub_rg_name=$4 # name of the hub rg
spoke_rg_name=$5 # name of the spoke rg

# Create the networking hubs resource group.
az group create -n $hub_rg_name -l $hub_rg_location

# Create the networking spokes resource group.
az group create -n $spoke_rg_name -l $spoke_rg_location

# Create the regional network hub.
az deployment group create -g $hub_rg_name -f networking/hub-default.json -p location=$resource_location

RESOURCEID_VNET_HUB=$(az deployment group show -g $hub_rg_name -n hub-default --query properties.outputs.hubVnetId.value -o tsv)

#Create the spoke that will be home to the AKS cluster and its adjacent resources.
az deployment group create -g $spoke_rg_name -f networking/spoke-BU0001A0008.json -p location=$resource_location hubVnetResourceId="${RESOURCEID_VNET_HUB}"


RESOURCEID_SUBNET_NODEPOOLS=$(az deployment group show -g $spoke_rg_name -n spoke-BU0001A0008 --query properties.outputs.nodepoolSubnetResourceIds.value -o tsv)

# Update the shared, regional hub deployment to account for the requirements of the spoke.
az deployment group create -g $hub_rg_name -f networking/hub-regionA.json -p location=$resource_location nodepoolSubnetResourceIds="['${RESOURCEID_SUBNET_NODEPOOLS}']" 

# Update the spoke networkId in the prod deployment config file
echo "updating the resource-id of the spoke virtual network to which the cluster would be mapped"
spokeVnetId=$(az network vnet show -g $spoke_rg_name -n vnet-spoke-BU0001A0008-00 --query id -o tsv)
echo $(cat azuredeploy.parameters.prod.json | jq --arg tagetVnetId "$spokeVnetId" '.parameters.targetVnetResourceId.value|=$tagetVnetId') > azuredeploy.parameters.prod.json

# Prod params after the upate of the targetVnetId
echo $(cat azuredeploy.parameters.prod.json)