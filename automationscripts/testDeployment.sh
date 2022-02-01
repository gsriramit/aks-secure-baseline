#!/bin/bash

#Cluster Parameters
RGNAMECLUSTER=$1
RGNAMESPOKES=$2
TENANT_ID=$3
SP_OBJECTID= $4

echo "Current working directory: $(pwd)"
echo "Value of Tenant Id:  $TENANT_ID"
echo "Value of SP Object Id: $SP_OBJECTID"

cd cluster-manifests/cluster-baseline-settings
echo "Current working directory after change: $(pwd)"