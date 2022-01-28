#!/bin/bash

apt install jq

# Step 2
# Create the TLS Certificates needed for the deployment of App-Gw and Traefik Ingress Controller

# execute the following commands from the context of the root folder
echo "Creating the TLS certificates"

export DOMAIN_NAME_AKS_BASELINE="contoso.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out appgw.crt -keyout appgw.key -subj "/CN=bicycle.${DOMAIN_NAME_AKS_BASELINE}/O=Contoso Bicycle" -addext "subjectAltName = DNS:bicycle.${DOMAIN_NAME_AKS_BASELINE}" -addext "keyUsage = digitalSignature" -addext "extendedKeyUsage = serverAuth"
openssl pkcs12 -export -out appgw.pfx -in appgw.crt -inkey appgw.key -passout pass:

export APP_GATEWAY_LISTENER_CERTIFICATE_AKS_BASELINE=$(cat appgw.pfx | base64 | tr -d '\n')

echo $(cat azuredeploy.parameters.prod.json | jq --arg app_gw_cert "$APP_GATEWAY_LISTENER_CERTIFICATE_AKS_BASELINE" '.parameters.appGatewayListenerCertificate.value|=$app_gw_cert') > azuredeploy.parameters.prod.json

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out traefik-ingress-internal-aks-ingress-tls.crt -keyout traefik-ingress-internal-aks-ingress-tls.key -subj "/CN=*.aks-ingress.${DOMAIN_NAME_AKS_BASELINE}/O=Contoso AKS Ingress"

export AKS_INGRESS_CONTROLLER_CERTIFICATE_BASE64_AKS_BASELINE=$(cat traefik-ingress-internal-aks-ingress-tls.crt | base64 | tr -d '\n')

echo $(cat azuredeploy.parameters.prod.json | jq --arg ingress_cert "$AKS_INGRESS_CONTROLLER_CERTIFICATE_BASE64_AKS_BASELINE" '.parameters.aksIngressControllerCertificate.value|=$ingress_cert') > azuredeploy.parameters.prod.json

echo "Completed Creating & Exporting the TLS certificates"