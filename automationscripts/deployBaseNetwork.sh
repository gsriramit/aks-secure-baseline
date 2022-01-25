#!/bin/bash

# assign the commandline values to local variables for readability
hub_rg_location=$1
spoke_rg_location=$2
resource_location=$3
hub_rg_name=$4
spoke_rg_name=$5

# Create the networking hubs resource group.
az group create -n $hub_rg_name -l $hub_rg_location

# Create the networking spokes resource group.
az group create -n $spoke_rg_name -l $spoke_rg_location

# Create the regional network hub.
az deployment group create -g $hub_rg_name -f networking/hub-default.json -p location=$resource_location

#RESOURCEID_VNET_HUB=$(az deployment group show -g $hub_rg_name -n hub-default --query properties.outputs.hubVnetId.value -o tsv)

#Create the spoke that will be home to the AKS cluster and its adjacent resources.
az deployment group create -g $spoke_rg_name -f networking/spoke-BU0001A0008.json -p location=$resource_location hubVnetResourceId="${RESOURCEID_VNET_HUB}"


#RESOURCEID_SUBNET_NODEPOOLS=$(az deployment group show -g $spoke_rg_name -n spoke-BU0001A0008 --query properties.outputs.nodepoolSubnetResourceIds.value -o tsv)

# [This takes about seven minutes to run.]
az deployment group create -g $hub_rg_name -f networking/hub-regionA.json -p location=$resource_location nodepoolSubnetResourceIds="['${RESOURCEID_SUBNET_NODEPOOLS}']"