# Challenge 1
A 3-tier environment is a common setup. Use a tool of your choosing/familiarity create these 
resources on a cloud environment (Azure/AWS/GCP). Please remember we will not be judged 
on the outcome but more focusing on the approach, style and reproducibility.

# Solution
- A typical 3-tier Env consist of a web tier, app tier & Database tier
- I've attached one typical 3-tier arch diagram which I found on the internet and explains simple implementation.
#### Assumptions
1. We are deploying this 3-tier setup in a hub and spoke model network.
2. All management resources like firewall, jumbox and domain controller are already in place.
3. Web traffic will be forwarded through the Application gateway that has already been created and placed in the hub network(one app gateway can handle multiple hosts so this resource is not required for each implementation and can be shared)
4. Management resources for Terraform are already there like a storage account to store state files and a key vault for storing secrets.
5. Backups are excluded from deployment assuming the backup is managed through Azure policy.
### Deployment
- I'm using Terraform to deploy this 3 tier setup.
- I'm currently deploying 2 VMs in web, app and DB tier, but the template is not restricted to this Multiple VMs can be deployed using this template, just need to increase the parameter in tfvars file.
- Load balancer is placed for only app tier assuming SQL high availability is achieved through Windows server failover cluster.
 #### This template will create the following resources

 - 1 Vnet with 3 subnets - web, app & DB.
 - Separate NSG for all 3 different subnets and attach them.
 - Create a NAT gateway with 1 public IP for outbound communication (only for cases where firewall is not in place).
 - Create peering with the Hub network.
 - 2 Web VMs in availability set.
 - 2 DB Vms in availability set.
 - 2 App VMs behind Internal load balancer in availability set.
 - Create necessary extensions for VMs.