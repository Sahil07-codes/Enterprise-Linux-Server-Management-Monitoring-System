# Part 08 tests

Local: `bash -n parts/part-08-healthcheck/files/elsm-healthcheck`; inspect threshold validation and strict config parsing.

Run `bash tests/unit/test-health-thresholds.sh` to exercise exact configured boundary values without modifying host state. Target RHEL: run `--help`, verify invalid/duplicate config exits 2, required dependency checks exit 3, `/srv/company` unmounted is critical, inactive required services are detected, absent optional NFS is `SKIP`, and critical state exits 1. Do not fill a filesystem. Compare report values to `df`, `/proc/meminfo`, `/proc/loadavg`, `systemctl`, and SELinux/firewall state. Verify report/log permissions are restrictive and no service was restarted. Target tests: NOT RUN.
