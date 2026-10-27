# Requirements traceability

| ID | Requirement | Evidence to capture | Status until target-VM testing |
|---|---|---|---|
| FR-01 | Canonical local users/groups | `getent`, `id`, provisioning output | NOT RUN |
| FR-02 | Department access and isolation | `getfacl`, positive/negative `sudo -u` tests | NOT RUN |
| FR-03 | Dedicated LVM/XFS data filesystem | `lsblk`, `pvs`, `vgs`, `lvs`, `findmnt` | NOT RUN |
| FR-04 | Persistent mount | `findmnt --verify` and reboot evidence | NOT RUN |
| FR-05 | Optional NFS lab export | `exportfs -v`, client mount/access; otherwise disclose absence | NOT RUN |
| FR-06 | Static internal Apache page | `systemctl`, local and permitted client `curl` | NOT RUN |
| FR-07 | Firewall and SELinux policy | active zone, allowlist, enforcing state, contexts | NOT RUN |
| FR-08 | Scheduled backup and verified restore | timer, archive manifest/checksum, restored sample comparison | NOT RUN |
| FR-09 | Truthful host health report | timestamped report with observations and thresholds | NOT RUN |
| FR-10 | Safe operational logs | owner/mode check and sample review | NOT RUN |
| FR-11 | Incident-response drills | drill record for detection through cleanup | NOT RUN |
| FR-12 | Reproducible documentation | fresh reviewer follows runbooks | NOT RUN |

Project files and static checks do not constitute evidence of VM-level acceptance. Use `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN` and include date, command, expected result, observed result, and evidence reference.

