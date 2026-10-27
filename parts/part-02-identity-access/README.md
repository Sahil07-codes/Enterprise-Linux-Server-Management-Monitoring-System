# Part 02: Identity and access

## Scope and dependencies

Provisions canonical local groups/users, a sudoers drop-in for `labadmin`, and company directory permissions. It never formats/mounts storage or changes global SSH, firewall, or SELinux settings. Part 03 must mount `/srv/company` first.

## Files included

- `files/provision-identities`
- `tests/README.md`
- `evidence/README.md`

## Installation

Review the script and confirm `/srv/company` is the intended dedicated filesystem. As root:

```bash
sudo dnf install acl
sudo bash parts/part-02-identity-access/files/provision-identities
```

Use `sudo bash parts/part-02-identity-access/files/provision-identities --dry-run` first to validate the mounted path, primary-group compatibility, and existing sudoers rule and preview the changes. The script refuses to create shared directories unless `/srv/company` is a mount point. It does not assign passwords; use `passwd USER` interactively after reviewing the account list. It creates `/etc/sudoers.d/elsm-labadmin` only if absent, validates it with `visudo`, and refuses to replace a different existing file.

## Access policy

Developers have write access to development; project readers have read-only access there. HR is limited to `hrteam`. Ops can write operations; project readers read only. Projects are read-only to developers, ops, and project readers; root publishes. `getfacl` and actual `sudo -u USER` tests are required.

## Optional SSH key setup and lockout prevention

From the trusted administrator workstation, install a public key using the platform's `ssh-copy-id` if available, or have the administrator append the public key to `/home/labadmin/.ssh/authorized_keys` after verifying it out of band. On the server, verify ownership and modes:

```bash
sudo chown -R labadmin:linuxadmins /home/labadmin/.ssh
sudo chmod 0700 /home/labadmin/.ssh
sudo chmod 0600 /home/labadmin/.ssh/authorized_keys
```

Keep the current session and VM console open. Test a new key-authenticated SSH session before changing any SSH daemon setting or closing the existing session. This part does not edit `sshd_config`; any global SSH hardening requires a reviewed change request and rollback plan.

## Verification and rollback

See `tests/README.md`. Before rollback, record user data and review dependent file ownership. Remove only the `elsm-labadmin` sudoers file after verifying its contents and use `visudo -cf`; account deletion is intentionally not automated. Remove lab users/groups only after an operator-reviewed data/ownership plan.

Acceptance: canonical memberships, validated sudo drop-in, mount guard, positive and negative access tests. Target-RHEL acceptance: NOT RUN (2026-10-27).

## Limitations and out-of-scope

Existing accounts are not deleted or assigned passwords. Existing primary-group mismatches stop execution. This part does not configure SSH keys; follow the master specification's secure optional procedure and preserve an active administrator session.
