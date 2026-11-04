# Zero-to-Hero Project Guide — Azure Enterprise 3-Tier Architecture

## 1. Business scenario
A business application must serve external users while protecting application logic and sensitive data. A flat network would let a compromised web host reach databases and secrets directly. The design separates web, application and data trust zones.

## 2. Target outcome
Expose only approved ingress, allow web-to-app traffic on required ports, allow app-to-data traffic on required ports, and keep PaaS dependencies private. Terraform makes network rules repeatable and reviewable.

## 3. Request flow
Client → controlled web ingress → web subnet → application subnet → private database endpoint. The application may also access Key Vault and Blob Storage over private endpoints. Return traffic is statefully handled; DNS must resolve private service names to private IPs.

## 4. Tool-by-tool
| Tool/service | Purpose | Key interview point |
|---|---|---|
| Terraform / AzureRM | Create VNet, subnets, NSGs, associations and private endpoints | Plan before apply; protect state |
| Azure VNet/subnets | Network address and trust segmentation | CIDRs must not overlap connected networks |
| NSGs | Stateful L3/L4 filtering | Rules are evaluated by priority; association is required |
| Azure Firewall (if used) | Centralized inspection and egress control | Not a replacement for subnet NSGs |
| Private Endpoint | Private IP connectivity to PaaS | Endpoint approval and subnet policy matter |
| Private DNS Zones | Resolve PaaS FQDN to private IP | DNS link/forwarding is a common failure point |
| Key Vault | Secret/certificate store | Prefer managed identity and RBAC |
| Storage / Azure SQL | Data services | Disable public access when private access is required |
| GitHub Actions | Terraform validation and security scan | PR checks are not live connectivity tests |
| Checkov / TFLint (if configured) | IaC checks | Explain advisory vs blocking behavior |

## 5. Implementation sequence
Define threat model and ports → allocate non-overlapping CIDRs → create VNet/subnets → create NSGs → associate NSGs → configure routes/ingress → create private endpoints and DNS → validate Terraform → inspect plan → deploy in sandbox → test allowed and denied paths.

## 6. Commands
```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
az network vnet show -g <rg> -n <vnet> -o json
az network nsg list -g <rg> -o table
az network nsg rule list -g <rg> --nsg-name <nsg> -o table
az network private-endpoint list -g <rg> -o table
```

## 7. Scenario-based Q&A
**Q1. Web tier is compromised. How do you limit lateral movement?**  
A: Web subnet should reach only the application listener on the exact required port. Deny direct database/management access, use a separate admin path, and monitor denied flows. Application-to-data access is separately scoped.

**Q2. App can connect to SQL by IP but not by hostname.**  
A: This points to DNS. Verify the private DNS zone, A record, VNet link, custom DNS forwarding and resolver configuration. Then verify route and NSG behavior independently.

**Q3. Is NSG enough to secure the application?**  
A: No. NSG is a network-layer control. Also require identity/RBAC, TLS, application authentication/authorization, host hardening, secrets management, patching, WAF/ingress controls and logging.

**Q4. Why does a private endpoint not automatically make a service private?**  
A: Public network access may remain enabled. Configure service firewall/public access settings, private DNS, route controls and verify public access is denied.

**Q5. A new NSG rule breaks production. What is the response?**  
A: Inspect effective security rules and flow logs, identify source/destination/priority, roll back the reviewed change or add the narrow required rule, then retest both permitted and denied flows.

## 8. Troubleshooting
Check subnet NSG association, priority conflicts, effective routes, overlapping CIDRs, private endpoint approval, DNS resolution, service firewall and application listener. Use Network Watcher where available.

## 9. Security/reliability/cost
Use least-privilege flows, no broad Any rules, dedicated admin access, private data services, zone/region resiliency appropriate to RTO/RPO, and avoid over-segmenting into unmanageable rule sets.

## 10. Learning path
TCP/IP and CIDR → Azure VNet/subnet → NSG and route tables → private endpoints/DNS → Terraform state/modules → CI security scans → live connectivity tests → failure injection and rollback.

## 11. Scope honesty
The repository is a Terraform reference foundation. Do not claim WAF, database deployment, end-to-end application connectivity or production traffic unless those components are present and tested.
