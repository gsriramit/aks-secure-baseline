## Node pool scale operation failures were detected due to a failure while bootstrapping the new nodes
### Summary	
We found node pool Grow operations that failed during the detection period due to a failure while bootstrapping the new nodes, in particular the Custom Script Extension setup failed. Once provisioned to the node pool, the Custom Script Extension downloads and executes scripts on Azure virtual machines. The extension is used for post deployment configuration, software installation, or any other configuration or management tasks.  
AKS uses the Custom Script Extension to provision Virtual Machines with software required to bootstrap Kubernetes Worker nodes in your node pools. These failures were found within the time range: 2022-01-15 05:35:00 ⇒ 2022-01-16 05:35:00

### Error
VM has reported a failure when processing extension 'vmssCSE'. Error message: "Enable failed: failed to execute command: command terminated with exit status=51
### Hit Count	3
### Resources	
|Node Pools|	Scale Sets| 	Instances |
|----------|---------------|--------------|
|npsystem, npuser01| aks-npsystem-40054496-vmss, aks-npuser01-40054496-vmss| aks-npsystem-40054496-vmss_10, aks-npuser01-40054496-vmss_6| 

### Root Cause
The baseline deployment template (clusterstamp.json) provides an empty array value for the "authorized IP ranges" parameter of the cluster configuration. This can be left empty if you still do not know the whitelist IP ranges. The next topic details the list of IP addresses and ports that need to be allowed. At a minimum, for the proper bootstrapping and working of the cluster, the Firewall's public IP needs to be added. 

### Recommended Action
Exit status 51 means the node was unable to establish a connection to k8s API server. Please ensure that all NSGs, RouteTables, and custom DNS servers are able to access the dependencies discussed in the link below:
[Required ports and addresses for AKS clusters](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic#required-outbound-network-rules-and-fqdns-for-aks-clusters)

### Solution
As per the recommendation in the troubleshooting guide the fix was to disable the Cluster authorized IP ranges to make sure that the network connectivity was in fact the issue
The following command was issued to nullify the authorized IP ranges param
srvadmin@DESKTOP-LP3ON48:/mnt/c/DevApplications/aks-secure-baseline$ az aks update --resource-group rg-bu0001a0008 --name aks-4vgqts35oun5k --api-server-authorized-ip-ranges ""


The resulting JSON object of the Cluster Configuration has the following section. All the nodes are now up and running

  "apiServerAccessProfile": {
    "authorizedIpRanges": null,
    "disableRunCommand": null,
    "enablePrivateCluster": false,
    "enablePrivateClusterPublicFqdn": null,
    "privateDnsZone": null
  },

### Take-away
Design the Authorized IP ranges to include the firewall public Ips, the router public IP (if using the kubect CLI from a local machine) and the load balancer's outbound IP (private or public)
