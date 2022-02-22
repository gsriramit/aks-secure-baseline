## Issue Description
Cluster provisioning fails due to an internal error
  
## Error Details
AKS encountered an internal error while attempting the requested Updating operation. AKS will continuously retry the requested operation until successful or a retry timeout is hit. Check back to see if the operation requires resubmission. Correlation ID: c020e339-d1ec-4355-b039-7d380adca5e4, Operation ID: d4c17227-e087-4f26-8f60-61f7e8f75e8a, Timestamp: 2022-01-29T15:24:37Z. (Code: **ProvisioningControlPlaneError**)  
{\"code\":\"CreateVMSSAgentPoolFailed\",\"message\":\"AKS encountered an internal error while attempting the requested Creating operation. AKS will continuously retry the requested operation until successful or a retry timeout is hit. Check back to see if the operation requires resubmission. Correlation ID: 1ca88d91-ed91-493c-8c43-87b989c09113, Operation ID: 2a3a0f80-9c65-47dd-8276-af9b01cca266, Timestamp: 2022-01-29T13:57:08Z.\"}]}}", (Sat Jan 29 2022 19:27:37 GMT+0)
	
### Observation
The self-healing capability of the platform tries to bring the cluster back to the healthy state. The Cluster gets back to the succeeded state but the system pods are in the waiting state forever
### Solution
No fix has been determined so far
### References
- https://github.com/Azure/AKS/issues/1972
- https://github.com/Azure/AKS/issues/1798

