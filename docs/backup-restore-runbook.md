# Backup and restore runbook

Part 07 backs up only the mounted `/srv/company` filesystem to `/var/backups/elsm`. It uses a systemd timer and creates checksum sidecars. Restore to a new temporary directory only; the script never restores live data automatically.

## Routine backup verification

```bash
sudo systemctl status elsm-backup.timer --no-pager
sudo systemctl list-timers --all
sudo journalctl -u elsm-backup.service --since today --no-pager
sudo tail -n 100 /var/log/elsm/backup.log
```

Confirm a new archive and `.sha256` sidecar exist. Since the checksum manifest contains the archive basename, verify it from its destination directory:

```bash
cd /var/backups/elsm
sudo sha256sum -c ARCHIVE.tar.gz.sha256
```

## Restore test

Create a uniquely named harmless sample file under `/srv/company`, run the backup service, and follow the restore commands in [Part 07](../parts/part-07-backup/README.md). Compare the restored sample with `cmp`, then remove only the created sample and temporary restore directory.

## Failure handling

An unmounted source is a hard failure. Check `findmnt /srv/company`, destination free space/permissions, config validation, the lock, systemd journal, and backup log. Do not bypass the mount check or restore over live data. Preserve existing archives during troubleshooting.
