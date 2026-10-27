# Test layout

- `static/`: shell syntax and source-tree checks, plus optional ShellCheck/Ansible validation.
- `unit/`: component tests using temporary files and mocked host commands where practical.
- `integration/`: explicitly invoked target-VM checks.
- `manual/`: operator checklists for storage, networking, reboot, and rollback.

## Complete safe test suite

Run from the repository root on Linux with Python 3.9+ and Bash:

```bash
python3 bin/elsm all --profile test \
  --report-dir /tmp/elsm-reports \
  --log-file /tmp/elsm-automation/automation.log
```

The runner executes the static check once, discovers each `tests/unit/test-*.sh` and `tests/unit/test_*.py` once, captures stdout, stderr, exit code, and duration, and continues independent tests after failures. The identity, health failure, and backup workflow tests require root because their production entry points enforce it. They use mocked commands and/or temporary fixtures; the backup test rewrites canonical paths only in a temporary script copy. Exit status `77` is reported as BLOCKED, not PASS. Missing optional ShellCheck and Ansible tools are reported as NOT RUN.

## Target validation

On RHEL 9, run:

```bash
python3 bin/elsm preflight
python3 bin/elsm validate
python3 bin/elsm status
```

`validate` runs the detailed read-only component status and lightweight smoke checks. `status` runs only the detailed component status checker. Neither configures or repairs the host. A result of `3` means a prerequisite is blocked or operator/remote acceptance review remains; use `tests/manual/acceptance-checklist.md` and record results separately.

Target VM tests require RHEL, a disposable lab, and appropriate permissions. Passing local tests is not target acceptance, reboot evidence, or proof of network exposure controls.

## Reports

Reports default to `/var/lib/elsm/reports/latest.txt` and `latest.json`; the append-only summary log defaults to `/var/log/elsm/automation.log`. Supply `--report-dir` and `--log-file` after the command to use another location. See [`docs/automation-guide.md`](../docs/automation-guide.md) for status meanings, deployment limits, and exit codes.
