# Part 01: Foundation and preflight

## Scope and dependencies

This part provides read-only environment discovery and the shared script convention. It does not configure hostname, networking, storage, users, services, firewall, or SELinux. Review `MASTER_SPEC.md` and the network plan first.

## Files included

- `files/elsm-preflight`
- `files/change-request-template.md`
- `tests/README.md`
- `evidence/README.md`
- shared `scripts/lib/common.sh`

## Files and use

- `files/elsm-preflight`: read-only RHEL host and repository report.
- `tests/README.md`: local syntax and target-host test steps.

Copy the script to a reviewed location or run it from the repository:

```bash
bash parts/part-01-foundation/files/elsm-preflight
```

It gathers release, kernel, hostname, address/route, NetworkManager connections, block devices, mounts, SELinux, failed units, and DNF repository status. Missing required discovery commands are reported and produce exit code 3. It never writes host configuration.

## Rollback, limitations, acceptance

No system state is changed, so no rollback is required. Repository readiness checks only report the DNF repository list; they do not enable repositories or install packages. RHEL-specific output must be inspected on the actual VM.

Acceptance: script displays all available preflight categories; missing dependencies are explicit; no configuration changes occur. Status: target-RHEL test **NOT RUN** (2026-10-27).

## Out-of-scope confirmation

This part does not change identities, storage, services, firewall, SELinux, backup, or health-check behavior.
