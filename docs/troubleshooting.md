# Troubleshooting

## Service will not start

1. `systemctl status SERVICE --no-pager`
2. `journalctl -u SERVICE -b --no-pager`
3. Run the service's configuration validator.
4. Check `ss -tulpn`, ownership, and permissions.
5. Check SELinux labels and recent AVCs while enforcing.
6. Apply a minimal fix owned by that component and repeat validation.

## Client cannot reach a service

Confirm both hosts are on the intended private LAN; inspect `ip -br address`, routes, listeners, and the active firewalld zone. Check name resolution, service logs, and SELinux. Never open all ports or disable the firewall as a shortcut.

## Company path missing

Inspect `lsblk -f`, `findmnt /srv/company`, `pvs`, `vgs`, `lvs`, `blkid`, and `findmnt --verify`. Do not recreate company directories on `/` as a workaround. Resolve the storage/mount failure first.

## Backup failed

Check source mount, destination permissions/free space, validated config, lock state, service journal, and backup log. List the archive and restore a test file to a temporary directory. Never restore over the live source as a troubleshooting shortcut.

## Suspected SELinux denial

Check `getenforce`, expected file/port labels, and AVC messages using available tools such as `ausearch`. Correct a justified label/boolean and retest in enforcing mode. Do not disable SELinux.

