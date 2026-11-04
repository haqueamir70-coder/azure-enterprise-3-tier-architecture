# Source Code Walkthrough — Azure Enterprise 3-Tier Architecture

> Reviewed against the repository's current `terraform/*.tf` source files on 4 November 2026. This document explains the actual code, not only the target architecture. It also calls out gaps that must be fixed before claiming production readiness.

## 1. Repository execution model

The Terraform root is under `terraform/`. Terraform loads all `.tf` files in that directory as one root module; the file split is for maintainability, not separate execution units.

Dependency flow:
- `versions.tf` constrains Terraform and provider versions.
- `main.tf` configures AzureRM and creates the resource group and VNet.
- `variables.tf` declares user-supplied inputs.
- `random.tf` generates a suffix used in globally unique names.
- `network.tf` creates subnets, NSGs and subnet associations.
- `security.tf` adds Defender pricing configuration and NSG rules.
- `compute.tf` creates the private web VM and NIC.
- `database.tf`, `storage.tf`, `keyvault.tf` create private PaaS services/endpoints/DNS.
- `frontdoor.tf` and `loadbalancer.tf` create edge/network resources, but currently do not complete a functioning ingress path.
- `backup.tf` creates a Recovery Services vault, but does not configure protected workloads or a backup policy.
- `monitoring.tf` creates Log Analytics and Application Insights, but no diagnostic settings or app instrumentation.
- `outputs.tf` exports resource group and region only.

## 2. File-by-file explanation

### `terraform/versions.tf`
- `required_version = ">= 1.6.0, < 2.0.0"` defines the supported Terraform CLI range. The upper bound prevents an unreviewed major-version jump.
- `required_providers.azurerm` selects HashiCorp's AzureRM provider and constrains it to the 5.x compatible series.
- `required_providers.random` pins the random provider to a compatible 3.6 series.
- **Interview point:** the version constraint is a compatibility range; the root lock file (if committed) selects the exact provider build/checksum used by init.
- **Check:** confirm `.terraform.lock.hcl` is committed in the Terraform root and provider upgrades are reviewed.

### `terraform/main.tf`
- `provider "azurerm"` configures the Azure provider; `features {}` is required provider configuration.
- `azurerm_resource_group.main` creates the resource group.
- `azurerm_virtual_network.vnet` creates VNet `10.0.0.0/16` and references the resource group name/location, establishing an implicit dependency.
- **Important code gap:** the file hard-codes `East US` and resource names even though `var.location` and `var.environment` exist. Use variables/locals for environment-specific values.
- **Interview point:** resource references create Terraform dependency edges; explicit `depends_on` is not needed when a real reference already expresses the dependency.

### `terraform/variables.tf`
- `location`: string with default `East US`.
- `environment`: string with default `dev`.
- `sql_admin_login`: string with a demo default.
- `sql_admin_password`: required string, marked `sensitive = true` and `nullable = false`.
- `ssh_public_key`: required string; public key is not secret material.
- **Important code gap:** `location` and `environment` are not consistently consumed by the current resources. The SQL login default should be reconsidered for a reusable module.
- **Security point:** `sensitive = true` redacts normal CLI output; it does not encrypt Terraform state. Protect state and provide the password through a secure environment/secret integration.

### `terraform/outputs.tf`
- Exposes resource group name and deployment region.
- Outputs are useful for composition and post-deployment scripts.
- **Improvement:** expose only useful non-secret IDs (VNet/subnet/private endpoint/SQL server IDs) when consumers need them. Never output SQL passwords, account keys or SAS tokens.

### `terraform/random.tf`
- `random_string.suffix` generates six lowercase alphanumeric characters.
- The suffix avoids collisions for names that require global uniqueness, such as Storage Account and Key Vault.
- **Interview point:** the random result is persisted in Terraform state; it remains stable between plans unless the resource is replaced.
- **Improvement:** consider a deterministic naming convention where operational traceability is more important than randomness.

### `terraform/network.tf`
- Creates four /24 subnets inside the /16 VNet: web `10.0.1.0/24`, app `10.0.2.0/24`, database `10.0.3.0/24`, and private endpoints `10.0.4.0/24`.
- Database and private endpoint subnets enable the NSG network-policy setting required by this design.
- Creates four NSGs: web, app, database and private endpoint.
- Associates each NSG with its matching subnet using `azurerm_subnet_network_security_group_association`.
- **Interview point:** creating an NSG alone does not enforce rules on a subnet; the association attaches the policy to the traffic path.
- **Improvement:** parameterize CIDRs, validate non-overlap, add explicit egress/route design and use Application Security Groups where they improve rule readability.

### `terraform/security.tf`
- Configures Defender for Cloud VM pricing at the Free tier; paid coverage is intentionally not enabled by this resource.
- Adds web inbound TCP 443 and 80 from the `VirtualNetwork` service tag.
- Allows TCP 8080 from web subnet `10.0.1.0/24` into the app NSG.
- Adds a low-priority-numbered deny rule for other VNet sources to the app tier.
- Allows TCP 1433 from app subnet `10.0.2.0/24` into the database NSG.
- Denies Internet inbound to the private-endpoint subnet and denies other VNet sources to the database tier.
- **Important security consideration:** `VirtualNetwork` is broader than one subnet and can include peered/connected ranges. The web-tier allow rules therefore permit more sources than a strict edge-ingress policy. Consider explicit ingress source ranges or a WAF/Application Gateway origin path.
- **Important ingress gap:** the rules do not create a public web ingress path. The VM has no public IP and no completed load-balancer/Front Door backend path.
- **Interview point:** lower numeric NSG priority is evaluated first; explicit allow/deny rules must be assessed together with Azure default rules and actual NSG association.

### `terraform/compute.tf`
- Creates a NIC in the web subnet with dynamic private IP allocation.
- Creates an Ubuntu 22.04 Linux VM of size `Standard_B1s`.
- Disables password-based SSH and uses `var.ssh_public_key`.
- Uses Standard_LRS OS disk.
- **Security positives:** no public IP is attached to the NIC; password authentication is disabled.
- **Gaps:** no VM extension/bootstrap/application deployment, no managed identity, no patch/backup association and no explicit boot diagnostics or disk encryption policy in this file.
- **Interview point:** a VM existing does not mean a web server or application is installed and healthy.

### `terraform/database.tf`
- Creates Azure SQL logical server with unique random suffix.
- Uses required admin login/password inputs and enforces minimum TLS 1.2.
- Disables SQL public network access.
- Creates a Basic database.
- Creates `privatelink.database.windows.net` private DNS zone and links it to the VNet.
- Creates a private endpoint targeting the SQL server's `sqlServer` subresource and associates the DNS zone.
- **Gap:** the file does not show an explicit SQL firewall policy, auditing configuration, Entra-only authentication or database-level user/role provisioning.
- **Operational point:** consumers need DNS resolution to the private endpoint IP and a network route from their source subnet.

### `terraform/storage.tf`
- Creates a Standard Storage Account with LRS replication.
- Enforces TLS 1.2, HTTPS-only, Shared Key disabled, public network access disabled and nested public items disabled.
- Creates a private Blob container.
- Creates the Blob private DNS zone, VNet link and private endpoint.
- **Security positives:** public access and Shared Key are disabled; the container is private.
- **Gap:** no role assignment grants a workload identity Blob data-plane access. A private endpoint gives network reachability, not authorization.
- **Improvement:** add lifecycle/retention/versioning/soft-delete settings and a narrowly scoped Storage Blob Data role for the actual workload identity.

### `terraform/keyvault.tf`
- Reads current Azure client configuration to obtain the tenant ID.
- Creates an RBAC-enabled Key Vault with public network access disabled, 90-day soft delete and purge protection.
- Configures network ACL default deny and no bypass.
- Creates the Key Vault private DNS zone, VNet link and private endpoint.
- **Security positive:** private access, RBAC authorization, soft delete and purge protection are enabled.
- **Critical gap:** no Key Vault role assignment grants a workload identity access to secrets/keys. Network access alone does not grant data-plane permissions.
- **Improvement:** create a dedicated workload identity and assign only the required Key Vault data-plane role at the narrowest scope.

### `terraform/frontdoor.tf`
- Creates an Azure Front Door Standard profile.
- Creates a WAF firewall policy in Prevention mode.
- **Critical gap:** no Front Door endpoint, origin group, origin, route, custom domain or security-policy association is created. The WAF policy is not yet protecting a routed application endpoint.
- **Interview point:** a WAF policy resource by itself does not mean traffic is routed through WAF.

### `terraform/loadbalancer.tf`
- Creates a static public IP.
- Creates an Azure Load Balancer with a public frontend referencing that IP.
- **Critical gap:** there is no backend address pool, NIC backend association, health probe or load-balancing rule. The resource does not currently distribute traffic to the web VM.
- **Security consideration:** the unused public IP is an exposed public resource but not a functional application ingress path. Decide whether the intended design is Front Door/WAF, Application Gateway or Load Balancer and implement one coherent path.

### `terraform/backup.tf`
- Creates a Recovery Services vault with Standard SKU.
- **Critical gap:** no backup policy, VM backup protection, retention schedule or restore validation is configured. A vault alone does not back up the VM.
- **Interview point:** distinguish backup control-plane resources from protected workload items and tested restore evidence.

### `terraform/monitoring.tf`
- Creates a Log Analytics workspace with 30-day retention.
- Creates workspace-based Application Insights.
- **Critical gap:** no Azure Monitor diagnostic settings connect the resource logs/metrics to the workspace, and the VM/application is not instrumented here.
- **Improvement:** add diagnostic settings for supported resources, VM monitoring/agent where needed, application telemetry and actionable alert rules. Monitor ingestion cost and retention.

## 3. Actual project-specific issues to fix

| Priority | Finding | Why it matters | Recommended action |
|---|---|---|---|
| High | Front Door profile/WAF policy have no endpoint/origin/route association | WAF is not protecting an application route | Implement endpoint, origin group, origin, route and security policy association, or remove unused resources |
| High | Load Balancer has no backend pool/probe/rule | Public frontend does not deliver traffic to VM | Add backend, health probe, rule and NIC association, or remove LB and use Front Door/Application Gateway |
| High | No workload RBAC for Key Vault or Storage | Private networking does not authorize data access | Add managed identity and least-privilege data-plane role assignments |
| High | SQL password exists in Terraform state after apply | Sensitive CLI redaction does not remove it from state | Protect backend, restrict state access, avoid outputs/logs and use managed identity/Entra SQL auth where feasible |
| Medium | `location` and `environment` inputs are not used consistently | Reuse across environments is incomplete | Introduce locals for naming/location and consume validated inputs |
| Medium | Backup vault has no protected item/policy | No actual VM backup is configured | Add policy, VM protection and restore test |
| Medium | Monitoring workspace has no diagnostic settings | Resource telemetry may not reach workspace | Add diagnostic settings, instrumentation and alert rules |
| Medium | Web NSG allows `VirtualNetwork` on 80/443 | Wider source scope than strict Internet ingress | Use WAF/App Gateway origin path and explicit source rules |
| Medium | SQL/database security controls are incomplete | Private endpoint alone does not cover auditing/authentication | Add auditing, Entra auth, firewall validation and database permissions |
| Medium | Hard-coded resource names and CIDRs | Environment reuse and collision management are limited | Use locals/variables, naming convention and CIDR validation |

## 4. Additional code-specific interview questions

### Q1. Why are all Terraform files in one directory one root module?
Terraform loads all `.tf` files in the working directory together. File names organize the code for humans; they do not create independent modules or execution order.

### Q2. How does Terraform know to create the resource group before the VNet?
The VNet references the resource group's name and location. Those references create implicit dependency edges in Terraform's graph.

### Q3. Why is a random suffix used?
Azure Storage Account names must be globally unique and Key Vault names must be unique within their DNS namespace. The random provider generates a stable suffix stored in state.

### Q4. Does sensitive=true protect sql_admin_password in state?
No. It redacts ordinary CLI display, but the value can still be stored in state. Backend encryption, access control and secure secret injection are still required.

### Q5. Does a private endpoint automatically disable public access?
No. The service's own public network access/firewall setting must also be configured. This code disables it for SQL, Storage and Key Vault.

### Q6. Does private endpoint automatically grant permission?
No. It provides a private network path. Azure RBAC/data-plane permissions are separate; the current Key Vault and Storage files lack workload role assignments.

### Q7. Why does the app subnet allow 8080 from 10.0.1.0/24?
It encodes the intended web-to-app tier flow and limits source to the web subnet. Confirm the actual application listens on 8080 and test both allowed and denied sources.

### Q8. Is VirtualNetwork a narrow source for public web ingress?
No. It can include connected/peered address ranges. A strict public edge should use an approved WAF/ingress service and explicit origin restrictions.

### Q9. Why does the Load Balancer not serve the VM yet?
The code creates only a public IP and frontend. It lacks backend pool membership, health probe and load-balancing rule.

### Q10. Is the WAF active because the firewall policy exists?
No. The Front Door endpoint, origin, route and security policy association are absent. The policy is not yet attached to a routed endpoint.

### Q11. Does the Recovery Services vault mean the VM is backed up?
No. A backup policy and protected VM item are required, followed by a restore test.

### Q12. Does creating Log Analytics collect every resource's logs automatically?
No. Diagnostic settings or agent/instrumentation configuration are required for relevant sources.

### Q13. What is the role of private DNS zone virtual network link?
It allows clients using the linked VNet's DNS resolution path to resolve the service FQDN to the private endpoint address.

### Q14. Why does the VM use an SSH public key?
The VM disables password authentication and uses public-key authentication. Only the public key belongs in Terraform input; the private key must remain with the operator.

### Q15. What would you inspect if the VM is unreachable?
Check VM power/boot diagnostics, NIC IP, subnet NSG association/rules, effective routes, admin access path and SSH key/user. This VM has no public IP, so a private admin route is required.

### Q16. How would you validate the SQL private endpoint?
Resolve the SQL FQDN from the app network, confirm the private IP, inspect endpoint connection state, route/NSG behavior and authenticate using an authorized database identity.

### Q17. How would you add a Storage workload permission?
Create/enable a workload identity and assign the minimum Blob data-plane role at container or account scope as required. Test allowed read/write and denied operations.

### Q18. Why use an NSG association resource separately?
It makes the relationship explicit and lets the NSG be attached to the intended subnet. Without association, its rules do not govern that subnet's traffic.

### Q19. How would you make this project reusable across dev/test/prod?
Use validated variables and locals for region, names, CIDRs, SKUs and environment; avoid fixed names; separate state per environment and test the resulting plans.

### Q20. What evidence is required before calling this a production-ready 3-tier system?
A functioning ingress route, app deployed and listening, database/Storage/Key Vault permissions, private DNS/connectivity tests, backup restore proof, diagnostic ingestion, security review, load tests and recovery runbooks.

## 5. Safe validation commands

Run from the `terraform/` directory in a sandbox subscription:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

Azure inspection examples:

```bash
az account show
az network vnet list -g <resource-group> -o table
az network nsg list -g <resource-group> -o table
az network private-endpoint list -g <resource-group> -o table
az monitor diagnostic-settings list --resource <resource-id>
```

Never run apply/destroy against a production subscription without an approved plan, backup/rollback plan, cost review and explicit authorization.

## 6. Evidence status

This walkthrough describes the Terraform source currently present. It does not claim that the resources have been deployed or that the incomplete ingress, RBAC, backup and monitoring paths work. Update the status only after collecting actual CI, Azure deployment and runtime test evidence.
