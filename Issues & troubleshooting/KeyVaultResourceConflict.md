## Issue Description
If the cluster is deleted at the end of each iteration, the deleted vault has to be explicitly purged
  
### Summary
  When subsequent deployments of the cluster are attempted after a cleanup of the previous run, the keyvault will only be soft-deleted. This results in failure of the deployment as we try to create a vault with the same name again. Azure compares the names with the vaults that have been deleted too.  
### Solution
Key-vault with soft-delete enabled (has to be purged before the next fresh deployment if the template creates one with the same name again)  
Steps:
1. Get the list of all deleted vaults (with soft-delete enabled)
	 - az keyvault list-deleted --subscription 695471ea-1fc3-42ee-a854-eab6c3009516  --resource-type vault
2. Delete the Vault that was created during the previous AKS deployment
	 - az keyvault purge --subscription 695471ea-1fc3-42ee-a854-eab6c3009516 -n kv-aks-4vgqts35oun5k
   - Reference: https://docs.microsoft.com/en-us/azure/key-vault/general/key-vault-recovery?tabs=azure-cli#key-vault-cli
