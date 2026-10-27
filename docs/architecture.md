# Architecture

## Baseline

One RHEL server on a private/host-only LAN provides local identity, department directories on a separate XFS filesystem, optional NFSv4, static Apache HTTP, backup scheduling, and read-only health reporting. An optional second RHEL client validates NFS and client access. Administration is performed from a trusted host using SSH or the VM console.

```text
Trusted admin host -- SSH/22 --> rhel-srv01
Private lab client  -- NFSv4 --> /srv/company (optional)
Private browser     -- HTTP/80 -> Apache static portal
```

`firewalld` is the network boundary and SELinux remains enforcing. Backups and health reports are local baseline services; this is not HA or off-host disaster recovery.

## Data flow and boundaries

- User access is controlled through local groups and filesystem ACLs.
- `/srv/company` is supplied by the separately provisioned `vg_elsm/lv_company` XFS filesystem.
- NFS, when enabled, exports only an approved mounted company path to the verified private subnet. It never uses `no_root_squash`.
- Apache serves only static content. The page is not a live monitoring UI and contains no logs/secrets.
- Backup archives are stored outside the source tree and restored to temporary paths for validation.
- The health checker reads system state and does not restart services or remediate.

## Deployment dependencies

Preflight -> storage -> identity/access -> Apache -> optional NFS -> backup/restore -> health report -> integrated security review -> integration and reboot tests. Security review can be drafted earlier but final rules require actual interface/zone/service discovery.

## Limitations

Local accounts do not provide centralized identity. The single server is a failure domain. Local backup is not off-host disaster recovery. HTTP is plaintext and intended only for the isolated lab.

