# Deployment Automation using Github Actions
The deployment of the baseline architecture has been automated using a bunch of bash shell scripts and a github workflow that stitches them up in the right order.  

## Environment Setup & Resource Deployment Scripts

| Script          | Purpose                                                                                                     |
|-----------------------|-------------------------------------------------------------------------------------------------------|
| registerSubscriptionRequisites.sh | Register the features for the target subscription |
| createTLSCertificates.sh | Create the TLS certificates that will be used by App-Gw and Traefik Ingress Controller |
| createK8sAADGroupsNUsers.sh | Setting the needed user accounts and groups in AAD. These will be used when setting up the cluster with Azure AD integrated Authorization |
| deployBaseNetwork.sh | Create the Base Hub and Spoke virtual networks to which the AKS and the other services will be deployed to |
| postClusterDeployment.sh | Deployment of Ingress & workload resources and Import of secrets and certs into the keyvault |

## Github Actions
Github workflow (deployBaselineCluster.yml) has been coded in the most simple way possible to invoke the scripts in the required order and has been setup to be invoked manually (workflow dispatch). You can change this to any other trigger that might be more suitable for your case.  
The repo by default provides a Kubernetes specific CD tool (Flux) that will listen for changes to the cluster manifests and trigger a deployment to the cluster automatically. The workflow does not make use of flux for simplicity reasons. You can modify the workflow to start using flux for **Continuous Deployments** to the cluster after the first time creation.  

## Steps
1. Create the SP principal that will be used for the automation
   - Assign the SP the necessary permissions
     - RBAC Role
       - Contributor
       - User Access Administrator
       - Key Vault Certificates Officer
     - Azure AD Role
       - User Administrator  
2. Create the necessary secrets in GitHub (repository secrets)
   - AZURE_CREDENTIALS
   - TENTANTID
3. Execute the Pre-Deployment script- predeployment.sh (Note that this script needs to be executed manually from the Azure Bash shell or Ubuntu WSL using an account that has the Global Admin Privileges)
   - Verify that the role assignments (AAD and RBAC) to the SP completed successfully
4 (optional) - Modify the GitHub actions (deployBaselineCluster.yml) file if needed. The sample provided in this forked repo provides a way to just automate the original implementation to a greater possible extent


## Please Note:
1. The automation scripts and GitHub actions in this repository are meant only to automate the steps provided in the base repo and do not include any enhancements or impacting modifications
2. The main necessity of this automation is to save costs (costs would be high even if you deallocate the firewall instance and stop the AKS cluster/Scale Down the Node Pools) & repeat the deployments as and when needed
3. You can modify the GitHub actions as you see fit to suit your needs
4. The same workflow can be enhanced to automate the deployment of "Advanced Microservices on AKS" architecture

