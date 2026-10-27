# Part 07: Backup and restore

## Scope and dependencies

This part backs up the mounted `/srv/company` filesystem to `/var/backups/elsm`. It installs its own script, configuration, service, and timer. It does not configure storage, directory ACLs, firewall, Apache, or health checks. The backup script requires root, GNU tar, sha256sum, flock, find, and a mounted source. Confirm `tar`, `coreutils`, `util-linux` (`flock`), and `findutils` are available on the target.

## Files included

- `files/elsm-backup`
- `files/backup.conf.example`
- `files/elsm-backup.service`
- `files/elsm-backup.timer`
- `tests/README.md`
- `evidence/README.md`
- [`docs/backup-restore-runbook.md`](../../docs/backup-restore-runbook.md)

## Install

Review the script, then as root:

```bash
sudo install -o root -g root -m 0750 parts/part-07-backup/files/elsm-backup /usr/local/sbin/elsm-backup
sudo install -d -o root -g root -m 0700 /etc/elsm
sudo install -o root -g root -m 0600 parts/part-07-backup/files/backup.conf.example /etc/elsm/backup.conf
sudo install -d -o root -g root -m 0700 /var/backups/elsm
sudo install -d -o root -g root -m 0750 /var/log/elsm
sudo install -o root -g root -m 0644 parts/part-07-backup/files/elsm-backup.service /etc/systemd/system/elsm-backup.service
sudo install -o root -g root -m 0644 parts/part-07-backup/files/elsm-backup.timer /etc/systemd/system/elsm-backup.timer
sudo systemctl daemon-reload
sudo /usr/local/sbin/elsm-backup --help
sudo /usr/local/sbin/elsm-backup
sudo systemctl enable --now elsm-backup.timer
```

Config parsing is data-only; the file is never sourced as shell code. Source, destination, and log paths are intentionally restricted to canonical project paths. The source must be the mounted XFS volume from `vg_elsm/lv_company`. Retention accepts 1–3650 days. Archives are root-only, timestamped, and accompanied by SHA-256 files. Retention deletes only old, regular, non-symlink ELSM archives and their checksum sidecars directly inside the canonical destination.

Run `sudo /usr/local/sbin/elsm-backup --dry-run` to list retention candidates without creating an archive, writing logs, or deleting files.

## Restore test
Create a harmless sample under `/srv/company`, run the backup, then verify and restore only that sample:

```bash
TEST_FILE=/srv/company/development/elsm-restore-test.txt
test ! -e "$TEST_FILE" || { printf 'Test file already exists; choose another name.\n' >&2; exit 1; }
printf 'ELSM restore verification sample\n' | sudo tee "$TEST_FILE" >/dev/null
sudo chown root:developers "$TEST_FILE"
sudo chmod 0640 "$TEST_FILE"
sudo /usr/local/sbin/elsm-backup
ARCHIVE=$(find /var/backups/elsm -maxdepth 1 -type f -name 'elsm-*.tar.gz' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d ' ' -f 2-)
test -n "$ARCHIVE"
sudo sh -c 'cd /var/backups/elsm && sha256sum -c "$(basename "$1").sha256"' sh "$ARCHIVE"
sudo tar -tzf "$ARCHIVE" | grep -Fx 'company/development/elsm-restore-test.txt'
RESTORE_DIR=$(mktemp -d)
sudo tar -xzf "$ARCHIVE" -C "$RESTORE_DIR" -- company/development/elsm-restore-test.txt
sudo cmp "$TEST_FILE" \
  "$RESTORE_DIR/company/development/elsm-restore-test.txt"
sudo rm -f -- "$TEST_FILE"
sudo rm -rf -- "$RESTORE_DIR"
```

The archive selection command picks the newest ELSM archive; inspect its output before verification. After recording the comparison, remove only the known sample and the exact temporary directory created above. Never extract over `/srv/company`.

## Verification, rollback, status

Use `systemctl status elsm-backup.timer`, `systemctl list-timers --all`, `journalctl -u elsm-backup.service`, and `/var/log/elsm/backup.log`. Rollback: disable the timer; stop any running backup service; preserve needed archives; remove only project-owned unit/config/script files after inspection and reload systemd.

Acceptance requires successful scheduled run, valid checksum, successful sample restore, and retention boundary verification. Target RHEL tests: NOT RUN (2026-10-27).
