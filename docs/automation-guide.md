# ELSM automation guide

## What the central CLI does

`bin/elsm` is a standard-library Python 3 command-line entry point for safe tests, preflight observations, read-only validation, planning, and private reports. It does **not** make this repository a complete deployment system. It never executes `mkfs`, `pvcreate`, `vgcreate`, `lvcreate`, partitioning commands, changes firewall/SELinux policy, creates system users, installs packages, or reboots the host.

The CLI's configuration is [automation.json](../config/automation.json). It holds report/log paths, canonical component paths, safe test locations, validation entry points, and the reviewed deployment dependency order. Component-owned thresholds/configuration remain in their per-part configuration files to avoid changing existing interfaces.

## Install or initialize

From a clean checkout on RHEL 9, inspect the files first, then make the entry point executable and run it using Python 3:

```bash
cd /opt/elsm
sudo install -d -o root -g root -m 0755 /opt/elsm/bin
sudo chmod 0755 /opt/elsm/bin/elsm
python3 /opt/elsm/bin/elsm --help
```

The project itself can remain in a user-owned checkout; reports use `/var/lib/elsm/reports` and the summary log uses `/var/log/elsm/automation.log` by default, so writing those defaults requires suitable privileges. For a local checkout, select safe temporary output paths:

```bash
python3 bin/elsm test \
  --report-dir /tmp/elsm-reports \
  --log-file /tmp/elsm-automation/automation.log
```

Reports are written atomically with mode `0600`; the append-only summary log also uses mode `0600`. For safety, custom outputs must be under `/tmp`, `/var/tmp`, or the current user's home directory; custom logs must be named `automation.log`, and an existing non-ELSM log is never appended to. The report retains subprocess output for diagnosis and should therefore be treated as operational data. Do not publish reports before reviewing and sanitizing them.

## Commands

```bash
python3 bin/elsm preflight
python3 bin/elsm test
python3 bin/elsm validate
python3 bin/elsm plan
python3 bin/elsm deploy --profile lab
python3 bin/elsm status
python3 bin/elsm report
python3 bin/elsm all --profile test
python3 bin/elsm all --profile lab
```

Use the common `--report-dir PATH` and `--log-file PATH` options after the subcommand when running without system report-directory privileges.

| Command | Behavior | Typical exit |
|---|---|---:|
| `preflight` | Reports Python/Bash, required repository assets, and whether the host is RHEL 9. It does not collect detailed host inventory; Part 01 remains the owner of that read-only report. | 0 pass; 1 failed prerequisite; 3 blocked/review |
| `test` | Runs static checks once, discovers each `tests/unit/test-*.sh` and `test_*.py` once, and records target acceptance as NOT RUN. Optional missing ShellCheck/Ansible is NOT RUN, not a pass. | 0 all required checks pass; 1 failure; 3 blocked |
| `validate` | Runs read-only component status and smoke checks. This is target-oriented and may fail on a development workstation. | 0 pass; 1 fail; 3 review/block |
| `status` | Runs the read-only detailed component status checker only. | 0 pass; 1 fail; 3 review/block |
| `plan` | Displays component order and prerequisites. Every deployment action is REVIEW REQUIRED. | 0 |
| `deploy --profile lab` | Deliberately plan-only; records deployment execution BLOCKED because no complete component apply interface exists. Makes no system changes. | 3 |
| `report` | Re-renders the latest JSON report, or records NOT RUN if no prior report exists. | Prior report exit code |
| `all --profile test` | Runs the safe test suite and writes the consolidated reports. | 0 pass; 1 fail; 3 blocked |
| `all --profile lab` | Runs preflight and safe tests, prints the dependency plan, and marks end-to-end deployment BLOCKED. It does not deploy. | 1 fail; 3 blocked/review |

Exit `2` is reserved for invalid CLI usage/configuration. Exit `3` means BLOCKED or REVIEW REQUIRED checks need a target/prerequisite/operator decision. Every test runs independently after a failure unless the runner cannot start.

## Reading the reports

- `latest.txt`: readable summary, each status, command, return code, duration, and captured output.
- `latest.json`: same result records in machine-readable JSON (`schema_version: 1`).
- `automation.log`: timestamped command and summary lines; it intentionally does not duplicate full command output.
- Both reports include environment metadata, check counts, elapsed subprocess time, configuration warnings, recorded host changes (empty for this plan/test-only CLI), and recommended next actions.

Statuses are distinct:

- `PASS`: executed and the expected automated condition passed.
- `FAIL`: executed and returned a failure.
- `BLOCKED`: required environment, privilege, or dependency is unavailable, or execution was intentionally withheld.
- `NOT RUN`: optional or target-specific acceptance was not attempted.
- `REVIEW REQUIRED`: an operator must compare the observation with the approved network/security plan or make a reviewed decision.

No RHEL deployment, remote-client acceptance, reboot persistence, or real XFS/LVM restore should be inferred from local component tests.

## Deployment and approval boundary

`plan` is safe to run on any host. `deploy` and `all --profile lab` do not apply changes. Follow [operations-runbook.md](operations-runbook.md) and each part's owner runbook manually. Disk identity/formatting, fstab changes, account/ACL provisioning, package installation, systemd enablement, firewall rules, SELinux changes, and NFS exports require their documented review and rollback steps. The operator must stop if a precondition is unclear.

The dependency sequence is:

```text
RHEL/host preflight
  -> identify and manually provision dedicated storage
  -> verify /srv/company
  -> identities and ACLs
  -> Apache and optional NFS
  -> reviewed firewall/SELinux policy
  -> backup service/timer and restore test
  -> health report
  -> integration, remote-client, and reboot acceptance
```

NFS is optional. Its server/client and source subnet must be reviewed separately. Part 10 Ansible is an optional identity example, not a deployment substitute.

## Failure handling and rollback

The CLI is read-only except for its own report/log outputs. If a check fails, inspect the result's full stdout/stderr and the component runbook. Do not retry a system-changing component blindly. Before operator-applied changes, snapshot the VM, keep console access, back up only the exact configuration being changed, and use the owning part's rollback steps. Storage destruction and restoring over live data are never generic rollback operations.

## Current acceptance state

Local unit/static checks are recorded in [local-validation-2026-10-27.txt](../evidence/local-validation-2026-10-27.txt). RHEL 9.6 deployment, reboots, real storage, remote firewall scope, second-VM NFS, and target Ansible idempotency remain NOT RUN until real target evidence is recorded.
