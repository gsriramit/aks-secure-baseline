## Issue Description
The execution of the AAD Pod Identity Manifests resulted in the following error
Error:
- unable to recognize "STDIN": no matches for kind "AzureIdentity" in version "aadpodidentity.k8s.io/v1"
- unable to recognize "STDIN": no matches for kind "AzureIdentityBinding" in version "aadpodidentity.k8s.io/v1"

## RootCause
The necessary CRDs need to be deployed to the cluster before the "AuzreIdentity" and the "AzureIdentityBinding" types can be created. This is a documented prerequisite. 

### Solution
Execute the manifests in the "aad-pod-identity.yaml" file in the cluster baseline settings folder.  
**Note**: If the execution of the AzureIdentityException kind errors out, run the 2 exceptions separately. Not sure why the Identity exception request fails with the error of unrecognized type.

### References
https://github.com/Azure/application-gateway-kubernetes-ingress/issues/116
