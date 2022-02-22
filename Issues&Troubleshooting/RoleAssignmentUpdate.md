## Issue Description
"Role Assignment Update not permitted" while redeploying AKS atop the existing virtual network

### Root Cause
After the deletion of the cluster, the assignment of the "Network Contributor" role to the cluster's managed identity still remains. This happens because the User-assigned identity's lifetime is not tied to the resource it is associated with (unlike the system-assigned identity)
- The error happens when the role assignment is attempted in the "EnsureClusterIdentityHasRbacToSelfManagedResources" nested deployment
- This probably should not happen in a green-field deployment 
### Solution
Identity and delete the role assignments so that the conflict does not happen (this can be included as a part of the clean-up script)
```
    $clusterIdentityObjectId=''
		$clusterIdentityRoleAssignments = Get-AzRoleAssignment -ObjectId $clusterIdentityObjectId
		foreach ($roleassignment in $clusterIdentityRoleAssignments){ Remove-AzRoleAssignment -InputObject $roleassignment}
```
### References: 
- https://stackoverflow.com/questions/61637124/azure-devops-pipeline-error-tenant-id-application-id-principal-id-and-scope
-  https://github.com/Azure/application-gateway-kubernetes-ingress/issues/363
- https://jasonmasten.com/2021/04/13/tenant-id-application-id-principal-id-and-scope-are-not-allowed-to-be-updated/
