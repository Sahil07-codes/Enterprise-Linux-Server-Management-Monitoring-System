# Evidence index

| ID | Requirement/test | Evidence file | Timestamp | Status | Notes |
|---|---|---|---|---|---|
| 01 | Host baseline | `evidence/01-host-baseline.txt` | - | NOT RUN | Capture sanitized output |
| 02 | Storage layout and mount | `evidence/02-storage-layout.txt` | - | NOT RUN | Include LVM, XFS, findmnt |
| 03 | Identity and access tests | `evidence/03-access-tests.txt` | - | NOT RUN | Include allowed and denied tests |
| 04 | Apache and network policy | `evidence/04-web-service.txt` | - | NOT RUN | No public IP details |
| 05 | SELinux/firewall | `evidence/05-security-checks.txt` | - | NOT RUN | Enforcing required |
| 06 | Backup/restore | `evidence/06-backup-restore.txt` | - | NOT RUN | No archive contents |
| 07 | Health report | `evidence/07-health-report.txt` | - | NOT RUN | Remove sensitive host detail |
| 08 | Reboot validation | `evidence/08-reboot-validation.txt` | - | NOT RUN | |
| 09 | Local static/component validation | `evidence/local-validation-2026-10-27.txt` | 2026-10-27 | PASS (local only) | Ubuntu WSL; RHEL deployment and target acceptance remain NOT RUN |
