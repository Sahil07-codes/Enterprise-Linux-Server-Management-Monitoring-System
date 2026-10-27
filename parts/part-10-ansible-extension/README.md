# Part 10: Optional Ansible extension

This extension is an optional, limited example, not a complete deployment playbook and not required for baseline acceptance. It manages a subset of local identity primitives only; it deliberately does not create all baseline identities, configure directory ACLs/sudoers, deploy storage/NFS/Apache/backup/health-check components, format storage, change mounts, configure firewall/SSH, or apply SELinux policy. The baseline remains an operator-driven manual deployment; see the root README and operations runbook.

## Files included

- `ansible.cfg`
- `inventory/hosts.example`
- `playbooks/site.yml`
- `tests/README.md`
- `evidence/README.md`

## Prerequisites and use

Install Ansible on a trusted controller. Copy `inventory/hosts.example` to a private local inventory and replace the documentation-only address with the verified lab address. Do not commit credentials; use SSH keys and, if variables contain secrets, Ansible Vault.

Review the playbook, then validate:

```bash
ansible-playbook -i inventory/hosts.example playbooks/site.yml --syntax-check
ansible-playbook -i inventory/hosts.example playbooks/site.yml --check --diff
ansible-playbook -i inventory/hosts.example playbooks/site.yml
ansible-playbook -i inventory/hosts.example playbooks/site.yml --check --diff
```

The second application should have no unintended changes. This playbook creates groups/users without passwords and locks the new accounts pending an interactive password/SSH enrollment process. It does not guarantee sudoers policy or department ACL parity; use Part 02 for the approved baseline.

Automated playbook syntax/idempotency validation has not been run in this environment. Syntax-check and check mode are not substitutes for applying to a disposable RHEL 9 target, confirming the resulting account state, and re-running check mode for idempotency.

## Rollback and status

Review account ownership and files before manually removing any account; no automatic deletion is provided. Remove only project-created accounts/groups after explicit review. Ansible controller/target validation: NOT RUN (2026-10-27).
