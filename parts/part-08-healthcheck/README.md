# Part 08: Read-only health report

## Scope and install

The checker reads host state and writes only its report/log. It never restarts services or deletes data. It requires root to write canonical report locations and uses a strict data-only config parser.

Dependencies are RHEL Bash, systemd, firewalld CLI, GNU coreutils, util-linux, findutils, and awk. The checker validates required command availability before collecting measurements.

## Files included

- `files/elsm-healthcheck`
- `files/healthcheck.conf.example`
- `tests/README.md`
- `evidence/README.md`

```bash
sudo install -o root -g root -m 0750 parts/part-08-healthcheck/files/elsm-healthcheck /usr/local/sbin/elsm-healthcheck
sudo install -d -o root -g root -m 0700 /etc/elsm
sudo install -o root -g root -m 0600 parts/part-08-healthcheck/files/healthcheck.conf.example /etc/elsm/healthcheck.conf
sudo /usr/local/sbin/elsm-healthcheck --help
sudo /usr/local/sbin/elsm-healthcheck
```

`--config FILE` may be used for a reviewed test copy; it does not change the report or log destinations.

The report is written atomically to `/var/lib/elsm/health/latest.txt`; the log is `/var/log/elsm/healthcheck.log`. Default disk thresholds are WARN 80% and CRITICAL 90%. The config includes load, memory, and backup freshness thresholds. Set `NFS_ENABLED=true` only when NFS is intentionally configured; otherwise it is `SKIP`. If the backup script is absent, backup freshness is `SKIP`.

## Interpretation and recovery

Each check reports actual observed values and configured thresholds. Any `CRITICAL` result exits 1; warnings are reported without a critical exit. Missing required dependencies exits 3; invalid config exits 2. A missing `/srv/company` mount is critical. The script does not silently treat command failures as healthy.

Review report and log ownership/modes. Rollback: remove only installed script/config and any separately added scheduling after reviewing ownership; no host service state is changed by the script.

Target measurement, threshold, and failure tests: NOT RUN (2026-10-27).
