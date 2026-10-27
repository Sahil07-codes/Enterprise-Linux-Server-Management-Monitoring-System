# Operations runbook

## Before deployment

1. Confirm this is a disposable RHEL VM; record release, kernel, hostname, addresses, routes, disks, mounts, SELinux, failed units, and repositories.
2. Take a VM snapshot and verify console access.
3. Confirm the intended private subnet and administrator source. Do not blindly apply example addresses.
4. Identify the added data disk with `lsblk -f`; do not proceed if its contents/signatures are unclear.

## Deployment sequence

1. Run the read-only preflight from Part 01.
2. Provision `/srv/company` using Part 03's operator-confirmed runbook.
3. Create identities and directories with Part 02; verify the mount before directory creation.
4. Deploy the static page and start/enable Apache with Part 05.
5. Configure NFS from Part 04 only if a client and private subnet are available.
6. Install backup script/config/service/timer from Part 07, run a backup, then restore a sample to a temporary directory.
7. Run the Part 08 health check and inspect its report.
8. Apply reviewed firewall/SELinux changes with console and rollback available.
9. Execute Part 09 acceptance, safe drills, and reboot validation.

## Routine checks

```bash
sudo systemctl --failed
sudo systemctl list-timers --all
sudo /usr/local/sbin/elsm-healthcheck
sudo journalctl -u elsm-backup.service --since today --no-pager
sudo findmnt /srv/company
getenforce
```

Review alert state and logs without pasting sensitive output into Git. Treat a missing `/srv/company` mount as a stop condition for data operations.

## Shutdown and teardown

Stop scheduled backup activity before removing configuration. Preserve or export data intentionally before unmounting storage. Disable only services actually enabled by this project. Remove only project-owned files after verifying exact paths and backups. Never wipe or reformat storage as part of generic teardown; disk destruction is a separate, explicitly confirmed operator action.

