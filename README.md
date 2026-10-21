# Azure 3-Tier Application Architecture (Terraform)

This repository is a learning and portfolio project for modelling selected Azure resources with Terraform. It is **not yet verified as a complete, production-ready three-tier platform**. The diagram illustrates a target architecture; check the Terraform files for the resources currently defined.

## Repository layout

- `terraform/` — Terraform root configuration
- `architecture-diagram.png` — architecture illustration
- `.github/` — workflow configuration, if present

## Current configuration notes

The Terraform directory currently contains configuration for a resource group, virtual network/networking, a Linux web VM, Azure SQL, Key Vault, storage, monitoring, load balancing, Front Door, security and backup resources. Some resources reference other resources or values that must be validated together before deployment. No successful deployment is claimed by this README.

## Prerequisites

- Terraform installed
- Azure CLI installed and authenticated (`az login`)
- An Azure subscription and permissions to create the selected resources
- An SSH public key for the Linux VM
- A SQL administrator password supplied securely at runtime

## Configure secrets safely

Do not place passwords or private keys in Terraform files or commit them to Git.

PowerShell example:

```powershell
$env:TF_VAR_sql_admin_password = Read-Host "SQL admin password" -AsSecureString
```

For Terraform's environment variable interface, provide the secret as a plain environment string in your shell/session without echoing it, or use a supported secret manager. Do not paste secrets into source control or chat. Set the SSH public key using a local `terraform.tfvars` file excluded by `.gitignore`, or another secure local input mechanism.

Required variables include:
- `sql_admin_password` (sensitive, no default)
- `ssh_public_key` (public key matching the private key you own)

## Validate before any deployment

Run from the `terraform/` directory:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

Review every planned resource, region, network exposure, and estimated cost before applying. Do not run `terraform apply` against a production subscription until validation and security review are complete.

## Security notes

- A hard-coded SQL password has been removed from the Terraform configuration. If the old value was ever used in a live environment, rotate it immediately; removing it from the current file does not erase it from Git history.
- The SSH key is now an input variable rather than a placeholder string. Supply your own public key.
- Review the SQL firewall rule that uses Azure's special `0.0.0.0` rule. Prefer private connectivity and narrowly scoped network access for real workloads.
- Key Vault purge protection, network restrictions, RBAC, diagnostics, monitoring, backups, and least-privilege access must be verified and configured for the target use case.
- Do not commit Terraform state, plan files containing sensitive values, credentials, or real `terraform.tfvars` files.

## Portfolio roadmap

- Resolve and validate all Terraform references and provider requirements.
- Add CI checks for format, validation, linting, and infrastructure security scanning.
- Add documented network flow and security boundaries.
- Add test evidence and a cost-aware teardown procedure after successful testing.

## Author

MD Amirul Haque · [GitHub profile](https://github.com/haqueamir70-coder) · [LinkedIn](https://www.linkedin.com/in/md-amirul-haque/)
