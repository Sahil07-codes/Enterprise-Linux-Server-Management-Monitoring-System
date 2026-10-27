# Script and automation inventory

This inventory records the scripts and service/timer artifacts present in the repository at the time of this update. “Read-only” refers to host configuration; some checks write their own report/log. Do not treat documentation examples as deployment automation.

## Component scripts

| Path | Purpose and effects | Privilege/configuration | Exit behavior and rerun safety |
|---|---|---|---|
| `parts/part-01-foundation/files/elsm-preflight` | Collects RHEL release, hostname, network, disks, filesystems, SELinux, failed units, and enabled repositories. Read-only. | No root assertion; requires listed host discovery tools. | 0 complete, 1 command failures, 2 usage, 3 missing required commands. Safe to rerun. |
| `parts/part-02-identity-access/files/provision-identities` | Ensures local groups/users, sudoers drop-in, directory ownership/modes, and ACLs. Changes host state. | Root; requires `/srv/company` to be a real canonical mount; validates existing primary groups and sudoers content. No password setting. `--dry-run` validates and describes actions. | 0 success, 1 operation/precondition failure, 2 usage, 3 missing dependencies. Intended to rerun; appends approved supplementary memberships. |
| `parts/part-03-storage/files/validate-storage` | Reports block devices and LVM; verifies `vg_elsm/lv_company`, XFS, `/srv/company`, and fstab. Read-only. | No root assertion; requires LVM/block/mount tools. | 0 valid, 1 mismatch or missing expected volume/mount, 2 usage, 3 missing dependencies. Safe to rerun. No creation/format command is provided. |
| `parts/part-06-security/files/security-audit` | Reports listeners, firewalld state/zones/rules, SELinux mode, and failed units. Read-only. | No root assertion; listener process details may be more complete as root. No config file. | 0 audit queries succeeded, 1 query failure, 2 usage, 3 missing required commands. Safe to rerun. |
| `parts/part-07-backup/files/elsm-backup` | Creates gzip tar archive/checksum, logs, and deletes only validated retention-expired ELSM archive/checksum pairs. Changes backup/log state. | Root; readable strict KEY=value config; canonical source/destination/log; mounted expected XFS LVM source. `--dry-run` lists retention candidates. | 0 success, 1 operation failure, 2 usage/config, 3 missing commands. Uses lock/temp files; rerun creates a new timestamped archive. |
| `parts/part-08-healthcheck/files/elsm-healthcheck` | Reads host health and writes a timestamped report plus log. It does not remediate host services. | Root for report/log writes; strict config. `--self-test-thresholds` exercises boundary logic. | 0 no critical findings, 1 critical findings, 2 usage/config, 3 missing dependency. Safe to rerun; report is replaced atomically and log appended. |

## Tests and central automation

| Path | Purpose and effects | Privilege/configuration | Exit behavior and rerun safety |
|---|---|---|---|
| `tests/static/check-shell.sh` | Syntax-checks discovered Bash entry points; runs ShellCheck and Ansible syntax checks when installed. No host configuration changes. | Bash; optional ShellCheck/Ansible. | Nonzero on syntax/lint/Ansible errors. Safe to rerun. |
| `tests/unit/test-config-validation.sh` | Tests invalid backup/health configurations. Temporary files only. | Bash; no root. | 0 pass; nonzero fail. Safe to rerun. |
| `tests/unit/test-health-thresholds.sh` | Tests configured disk threshold boundaries. Temporary config only. | Bash; no root. | 0 pass; nonzero fail. Safe to rerun. |
| `tests/unit/test-identity-validation.sh` | Mocks host identity/mount commands and exercises identity dry-run/conflict handling. | Bash; root due to production script's root guard. | 0 pass; 77 skipped without root; other nonzero fail. Temporary fixture only. |
| `tests/unit/test-storage-validation.sh` | Mocks LVM/mount inspection and tests expected/mismatched/unmounted filesystems. | Bash; no root. | 0 pass; nonzero fail. Temporary fixture only. |
| `tests/unit/test-healthcheck-failures.sh` | Mocks service/disk/firewall/SELinux commands and checks critical report/exit behavior. | Bash; root due to report writer. | 0 pass; 77 skipped without root; other nonzero fail. Temporary fixture only. |
| `tests/unit/test-backup-workflow.sh` | Executes a canonical-path-rewritten temporary script against fixture data; tests archive/checksum/retention/failure cleanup/restore. | Bash; root due to backup ownership/root guards. | 0 pass; 77 skipped without root; other nonzero fail. Temporary fixtures only. |
| `tests/unit/test_automation_cli.py` | Exercises CLI parsing, capture, status/exit aggregation, discovery, JSON reporting, permissions, and plan-only behavior. | Python 3.9+ standard library; no root. | 0 pass; nonzero fail. Temporary directory for report files. |
| `tests/integration/elsm-smoke-check` | Read-only on-host smoke checks for RHEL, mount, services, SELinux, and firewalld. | Target RHEL and component tools; no changes. | 0 checks pass, 1 unmet condition, 2 usage. Safe to rerun. |
| `tests/integration/elsm-status` | Detailed read-only component status; reports active firewall rules/listeners and verifies local file labels when tools exist. | Target host; some checks require root visibility. Does not verify network reachability. | 0 automated checks pass, 1 failures, 2 operator/remote acceptance review remains. Safe to rerun. |
| `bin/elsm` | Central preflight/test/validate/plan/deploy/status/report/all interface. Writes only private report/log files; `deploy` is plan-only and BLOCKED. | Python 3.9+; Bash for shell checks; defaults report output under `/var`. Supports alternate report/log paths. | 0 pass, 1 failure, 2 usage/config, 3 blocked/review required. Safe to rerun. |

## Service and timer units

| Path | Purpose and effects | Prerequisite/privilege | Validation |
|---|---|---|---|
| `parts/part-07-backup/files/elsm-backup.service` | Runs the backup script as root with restrictive systemd sandboxing, read-only source, and declared writable backup/log/lock paths. | Must be reviewed/installed by an operator; requires `/srv/company`. | `systemd-analyze verify`, `systemctl status`, journal, archive/checksum/restore test on target. |
| `parts/part-07-backup/files/elsm-backup.timer` | Schedules the service daily with persistent catch-up and randomized delay. | Operator installs/enables it. | `systemctl list-timers --all` and reboot acceptance. |

## Configuration and templates

| Path | Purpose and handling |
|---|---|
| `config/automation.json` | Central automation CLI paths, script/test discovery, target-only acceptance items, and deployment dependency plan. It does not replace component-specific config parsers. Repository script paths must resolve inside the checkout; report/log output paths must be absolute. |
| `parts/part-07-backup/files/backup.conf.example` | Plain strict KEY=value backup source, canonical destination/log paths, and retention days. Installed/edited by an operator as `/etc/elsm/backup.conf`; the backup script parses it as data, never sources it. |
| `parts/part-08-healthcheck/files/healthcheck.conf.example` | Plain strict KEY=value disk, memory, load, backup-age, and optional-NFS thresholds. Installed/edited by an operator as `/etc/elsm/healthcheck.conf`. |
| `parts/part-04-nfs/files/elsm.exports.example` | Reviewed sample NFS export with root squashing. Must be adjusted only for the verified private subnet before operator installation. |
| `parts/part-10-ansible-extension/ansible.cfg` | Ansible behavior/configuration for the optional extension. |
| `parts/part-10-ansible-extension/inventory/hosts.example` | Documentation-only example inventory; copy to a private inventory and replace the example address before any target use. |

## Ansible playbook

`parts/part-10-ansible-extension/playbooks/site.yml` is an optional identity example. It creates selected groups and locked accounts, and skips existing accounts rather than reconciling all user fields. It does not configure storage, directory ACLs/sudoers parity, NFS, Apache, backup, health, firewall, or SELinux. Syntax is checked by the static test when Ansible is installed; apply/idempotency on RHEL remains NOT RUN.
