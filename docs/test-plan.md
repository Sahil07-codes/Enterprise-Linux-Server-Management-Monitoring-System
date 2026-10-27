# Test plan

## Result vocabulary

`PASS` = command executed and expected behavior observed. `FAIL` = executed with an unmet expectation. `BLOCKED` = a real prerequisite is unavailable. `NOT RUN` = not executed. Include timestamp, environment, command, expected result, observed result, status, and evidence path.

## Test layers

1. Static: Bash syntax, ShellCheck if available, Ansible syntax if `ansible-playbook` is available, path/name consistency, secret/artifact review.
2. Component: `tests/unit/` exercises config rejection, health thresholds/failure reporting, identity preflight conflicts, storage mount validation, and backup creation/checksum/retention/failure/restore integrity.
3. Integration: run `tests/integration/elsm-status` for read-only component observations, then validate identities, filesystem, services, network policy, backup/restore, and health report on a target.
4. Reboot: mount, enabled services, timer, firewall, SELinux.
5. Negative: denied cross-department access, missing/unmounted source, invalid config, optional NFS behavior.
6. Recovery: service drill and sample restore to temporary path.
7. Documentation: clean reviewer follows the setup without oral instructions.

## Minimum command checks

```bash
bash tests/static/check-shell.sh
bash -n parts/part-01-foundation/files/elsm-preflight
bash -n parts/part-02-identity-access/files/provision-identities
bash -n parts/part-07-backup/files/elsm-backup
bash -n parts/part-08-healthcheck/files/elsm-healthcheck
```

On the RHEL VM, use the verification commands in each part README and the catalogue in `MASTER_SPEC.md`. Run `sudo -u USER` positive and negative tests with harmless test files only. Do not run destructive storage experiments on the OS disk.

The status runner cannot infer the approved source CIDRs or prove remote reachability. Compare its reported active zone, firewall rules, listeners, and SELinux context checks with the reviewed network plan; complete remote-client, reboot, and second-VM checks manually. The project intentionally has no one-command installer: target-specific storage formatting, firewall policy, and SELinux changes remain reviewed operator actions. Part 10 Ansible is a limited optional identity example, not a deployment orchestrator.

## Baseline gates

- Host/network plan confirmed; extra disk positively identified.
- XFS `/srv/company` mount persistent and verified after reboot.
- Identity and ACLs match the contract; positive and negative access tests.
- Apache available only on intended private network; SELinux enforcing.
- NFS end-to-end tested or explicitly blocked/not run because there is no client.
- Backup timer runs; archive manifest/checksum and test restore validate.
- Health report contains real measurements; critical results return non-zero.
- At least five controlled incident drills documented.
- No secrets, VM artifacts, archives, or private logs committed.
