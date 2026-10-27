# Incident drills

Perform only in the disposable lab. Record setup, timestamp, expected symptom, diagnosis, remediation, verification, cleanup, status, and evidence. Keep console access. Never break SSH/network access or fill the OS filesystem.

## 1. Apache stopped

Stop `httpd` in a controlled maintenance window, confirm the health check detects it, inspect `systemctl` and journal, start it again, verify local `curl`, and clean up. Do not expose the site publicly.

## 2. Harmless permission mismatch

Use a temporary test directory under `/srv/company/development` after confirming the mount. Apply a restrictive mode to the test item only, observe the expected denial, inspect `namei`/`getfacl`, restore intended test permissions, verify access, then remove only that temporary item.

## 3. Backup and restore

Create a harmless uniquely named sample file, run backup, verify checksum/manifest, restore to a `mktemp` directory, compare contents, and remove only the temporary restore and sample file.

## 4. Threshold simulation

Use the health check's configured threshold/test mechanism only if implemented and documented. Otherwise test its pure threshold comparison in a temporary test harness. Do not fill any filesystem.

## 5. Invalid copied configuration

Copy a sample config to a private temporary location, make a documented invalid value, confirm validation fails non-zero, and remove only the temporary copy. Never corrupt the active config.

## 6. SELinux denial investigation (optional)

Use a harmless, isolated test with an incorrect label only if a snapshot and console access are available. Observe AVC evidence, restore the original label immediately, and validate enforcing mode. Do not disable SELinux.

## 7. Optional NFS absent

When NFS is not part of the lab, verify the health check reports the service as `SKIP`; do not stop a service used by another workload.

