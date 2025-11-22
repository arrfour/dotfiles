## Purpose
Provide concise, actionable guidance so an AI coding agent can be productive in this repository.

## Big picture
- Cloudblock deploys an end-to-end DNS+adblock appliance (WireGuard VPN + Pi-hole + cloudflared) as Docker containers.
- Terraform (per-provider folders) provisions cloud infrastructure; Ansible (under `playbooks/`) configures the VM and starts Docker services.

## Key locations
- Provider Terraform: `azure/`, `aws/`, `do/`, `gcp/`, `lightsail/`, `oci/`, `scw/`.
- Local provisioning: `playbooks/` (`cloudblock_amd64.yml`, `cloudblock_arm64.yml`, `cloudblock_raspbian.yml`).
- Documentation: `cloudblock/README.md` and each provider's `README.md` contain step-by-step workflows and variable descriptions.

## Concrete commands (copyable)
- Azure (WSL on Windows recommended):
```powershell
cd cloudblock/azure
terraform init
terraform apply -var-file="az.tfvars"
```
- Tail provision logs on the VM:
```bash
ssh ubuntu@<vm-ip>
sudo tail -F /var/log/cloudblock.log
```
- Local (standalone) Ansible deploy:
```bash
cd cloudblock/playbooks
ansible-playbook cloudblock_amd64.yml --extra-vars="doh_provider=opendns dns_novpn=1 wireguard_peers=10 vpn_traffic=dns"
```

## Conventions & patterns (project specific)
- Secrets live in provider `*.tfvars` (e.g. `az.tfvars`). Don't commit them; set perms (`chmod 600`) and use environment/CI secrets.
- Networking defaults use `172.18.0.0/24` (Docker) and `172.19.0.0/24` (WireGuard). Check for overlaps before changing addresses.
- WireGuard uses `51820/udp` — ensure your security groups / firewall allow it.
- Container names to reference on the VM: `cloudflared_doh`, `pihole`, `web_proxy`, `wireguard`.

## Where to change code
- Infra: edit files in `cloudblock/<provider>/` and keep provider `*.tfvars` local.
- Provisioning: edit `playbooks/` for Ansible tasks and variables.
- Docs: update the provider `README.md` and top-level `cloudblock/README.md` to reflect changes.

## Debugging & validation
- VM reachability: `ping` or `ssh ubuntu@<ip>`.
- Containers: `docker ps` on the VM to verify running services.
- To update mgmt/IP rules: edit the provider `*.tfvars` (`mgmt_cidr`) and re-run `terraform apply -var-file="<file>"`.

## Examples and references
- `cloudblock/playbooks/cloudblock_amd64.yml` — how containers are created and which variables are required.
- `cloudblock/azure/az.tfvars` and `cloudblock/azure/README.md` — example var names: `ph_password`, `ssh_key`, `mgmt_cidr`.

## Scope & limits for AI agents
- Keep changes small and localized (one subsystem at a time). Open a pull request for larger or cross-cutting changes.
- Never create or commit secrets. If testing requires secrets, request sanitized examples or use CI-provided secrets.

## When to ask the human
- Missing provider credentials or `*.tfvars` values required for testing.
- Any intended change to default networks, peer counts, or firewall rules that may impact existing deployments.

---
If you'd like, I can now move/delete the duplicate file you have outside the repo, or create a personal branch for your work and push it to origin.
