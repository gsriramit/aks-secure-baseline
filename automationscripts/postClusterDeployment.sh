#!/bin/bash

#Cluster Parameters
RGNAMECLUSTER=$1
RGNAMESPOKES=$2
TENANT_ID=$3
SP_OBJECTID= $4

# The target cluster to which the resources will be deployed
AKS_CLUSTER_NAME=$(az deployment group show -g $RGNAMECLUSTER -n cluster-stamp --query properties.outputs.aksClusterName.value -o tsv)
# The user-assigned MI that will be assigned to the ingress controller pods- this will be used internally to authenticate to AAD and get the access tokens to read certs from keyvault
TRAEFIK_USER_ASSIGNED_IDENTITY_RESOURCE_ID=$(az deployment group show -g $RGNAMECLUSTER -n cluster-stamp --query properties.outputs.aksIngressControllerPodManagedIdentityResourceId.value -o tsv)
TRAEFIK_USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az deployment group show -g $RGNAMECLUSTER -n cluster-stamp --query properties.outputs.aksIngressControllerPodManagedIdentityClientId.value -o tsv)
# the common keyvault that will be used for the shared resources (Ingress and AppGw certificates) and the app specific secrets
KEYVAULT_NAME=$(az deployment group show -g $RGNAMECLUSTER -n cluster-stamp --query properties.outputs.keyVaultName.value -o tsv)
# the original version of the cluster-stamp.json does not contain an output variable that holds the public IP of the app-gw. Updated code is yet to be tested
#APPGW_PUBLIC_IP=$(az deployment group show -g $RGNAMESPOKES -n spoke-0001 --query properties.outputs.appGwPublicIpAddress.value -o tsv)
APPGW_PUBLIC_IP=$(az network public-ip show -g $RGNAMESPOKES -n pip-BU0001A0008-00 --query "ipAddress")

# Create the keyvault access policy that lets the SP import the ingress controller certificate into the vault
az keyvault set-policy --certificate-permissions import get -n $KEYVAULT_NAME --object-id $SP_OBJECTID
# Use the Azure RBAC assignment instead of the keyvault access policies?
# TEMP_ROLEASSIGNMENT_TO_UPLOAD_CERT=$(az role assignment create --role a4417e6f-fecd-4de8-b567-7b0420556985 --assignee-principal-type user --assignee-object-id $(az ad signed-in-user show --query 'objectId' -o tsv) --scope $(az keyvault show --name $KEYVAULT_NAME_AKS_BASELINE --query 'id' -o tsv) --query 'id' -o tsv)

# Create the .pem file from the crt and key files and import into keyvault
cat traefik-ingress-internal-aks-ingress-tls.crt traefik-ingress-internal-aks-ingress-tls.key > traefik-ingress-internal-aks-ingress-tls.pem
az keyvault certificate import --vault-name $KEYVAULT_NAME -f traefik-ingress-internal-aks-ingress-tls.pem -n traefik-ingress-internal-aks-ingress-tls

#Set the cluster context and authenticate as admin
#Note: this is not the recommended practice, however this is considered as a workaround for the issue stated in this thread
#https://serverfault.com/questions/963481/how-to-grant-a-service-principal-access-to-aks-api-when-rbac-and-aad-integration
az aks get-credentials -n ${AKS_CLUSTER_NAME} -g ${RGNAMECLUSTER} --admin

# install the kubectl client in the runner
az aks install-cli
echo "kubectl version is $(kubectl version --client)"

# Create the cluster baseline namespace and apply the flux config
kubectl create namespace cluster-baseline-settings
kubectl apply -f cluster-manifests/cluster-baseline-settings/flux.yaml
kubectl wait --namespace cluster-baseline-settings --for=condition=ready pod --selector=app.kubernetes.io/name=flux --timeout=90s
kubectl create namespace a0008

#Apply the aad-pod-identity manifests- Without this being applied the following errors are thrown
#unable to recognize "STDIN": no matches for kind "AzureIdentity" in version "aadpodidentity.k8s.io/v1"
#unable to recognize "STDIN": no matches for kind "AzureIdentityBinding" in version "aadpodidentity.k8s.io/v1"
#ToDo- the AzureManagedIdentity feature added to the subscription should have installed these CRDs? No?
kubectl apply -f cluster-manifests/cluster-baseline-settings/aad-pod-identity.yaml

ACR_NAME=$(az deployment group show -g $RGNAMECLUSTER -n cluster-stamp --query properties.outputs.containerRegistryName.value -o tsv)
# Import ingress controller image hosted in public container registries
az acr import --source docker.io/library/traefik:v2.5.3 -n $ACR_NAME


echo ""
echo "# Creating the AzureIdentity and AzureIdentity binidng that enable the aad-pod-identity mechanism"
echo ""

# unset errexit as per https://github.com/mspnp/aks-secure-baseline/issues/69
set +e
echo $'Ensure Flux has created the following namespace and then press Ctrl-C'
# kubectl get ns a0008 --watch

echo "Creating the Identity and Binding for the Ingress Controller Pods"
cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
  name: podmi-ingress-controller-identity
  namespace: a0008
spec:
  type: 0
  resourceID: $TRAEFIK_USER_ASSIGNED_IDENTITY_RESOURCE_ID
  clientID: $TRAEFIK_USER_ASSIGNED_IDENTITY_CLIENT_ID
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: podmi-ingress-controller-binding
  namespace: a0008
spec:
  azureIdentity: podmi-ingress-controller-identity
  selector: podmi-ingress-controller
EOF

cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aks-ingress-tls-secret-csi-akv
  namespace: a0008
spec:
  provider: azure
  parameters:
    usePodIdentity: "true"
    keyvaultName: "${KEYVAULT_NAME}"
    objects:  |
      array:
        - |
          objectName: traefik-ingress-internal-aks-ingress-tls
          objectAlias: tls.crt
          objectType: cert
        - |
          objectName: traefik-ingress-internal-aks-ingress-tls
          objectAlias: tls.key
          objectType: secret
    tenantId: "${TENANT_ID}"
EOF


# Deploy the ingress controller and the actual workload deployments
kubectl apply -f workload/traefik.yaml
kubectl apply -f workload/aspnetapp.yaml


echo 'the ASPNET Core webapp sample is all setup. Wait until is ready to process requests running'
kubectl wait --namespace a0008 \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=aspnetapp \
  --timeout=90s
echo 'you must see the EXTERNAL-IP 10.240.4.4, please wait till it is ready. It takes a some minutes, then cntr+c'
echo $(kubectl get svc -n traefik --watch  -n a0008)