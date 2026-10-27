# Part 09: Integration and acceptance

## Scope and dependencies

Integrates Parts 01–08 without silently rewriting their behavior. Owns the final test matrix, operations/troubleshooting/incidents documentation, and evidence index. Run only after component prerequisites exist.

## Files included

- `tests/integration/elsm-smoke-check`
- `tests/integration/elsm-status`
- `tests/manual/acceptance-checklist.md`
- `docs/test-plan.md`
- `docs/incident-drills.md`
- `docs/operations-runbook.md`
- `docs/troubleshooting.md`
- `docs/evidence/evidence-index.md`

## Deployment and acceptance

Follow `docs/operations-runbook.md`; deployment is manual and there is no end-to-end installer. Run `tests/integration/elsm-status` for read-only component checks and `tests/integration/elsm-smoke-check` for a lightweight smoke test, then complete `tests/manual/acceptance-checklist.md`. The status runner prints active firewall zones/rules and listening sockets for review, verifies available SELinux labels, and flags source-CIDR/remote-client checks for operator confirmation. It does not apply settings or prove reachability from a second host.

Run positive and negative identity tests, service/network tests, backup/restore, health status/threshold checks, optional NFS tests, and reboot verification. No VM has been provisioned from this repository, so all target runtime results remain NOT RUN.

At least five incident drills must include setup, symptom, diagnosis, remediation, verification, and cleanup. Use only disposable test items and do not fill the OS filesystem or break management access. Integration status: NOT RUN (2026-10-27).

## Status and rollback

Record each requirement as PASS, FAIL, BLOCKED, or NOT RUN with timestamp, exact command, expected and actual output, and a sanitized evidence reference. Do not mark a test PASS based on documentation or another part's assertion. Integration itself changes no system configuration; component rollback belongs to each owner.

## Out-of-scope confirmation

This part does not rewrite component scripts, alter storage, or change firewall/SELinux/service configuration.
