# Automation safety review

## Scope and limitations

Review scope: the central `bin/elsm` workflow, `config/automation.json`, status/test entry points, report/log writes, and the reviewed deployment boundary. This is a repository-level safety review, not a penetration test, independent security audit, RHEL hardening certification, or proof of network exposure. No RHEL host or second VM was available for live review.

## Controls verified in code

- `test`, `preflight`, `validate`, `status`, `plan`, and `report` do not invoke component deployment scripts. Target validation runs only the read-only integration scripts and only on a detected RHEL 9 host.
- `deploy --profile lab` records BLOCKED and invokes no host command. The lab profile does not perform automatic package, account, mount, firewall, SELinux, systemd, storage, or reboot changes.
- Repository-script paths configured for discovery resolve within the project tree; tests are limited to the configured unit-test directory.
- Reports are atomically written as mode `0600`; log summaries are mode `0600` and are not appended to unless an existing log has the ELSM marker. Symlinked output paths and non-regular output files are rejected.
- Custom report/log paths are restricted to `/tmp`, `/var/tmp`, or the current user's home. Custom logs must be named `automation.log`.
- Component storage creation remains manual; the project does not provide an automated `pvcreate`, `vgcreate`, `lvcreate`, partition, `wipefs`, or `mkfs` path.
- Firewall and SELinux changes remain explicitly reviewed operations. The status command reports current state but does not remediate it.

## Residual risks and required target review

| Area | Finding / required action | Status |
|---|---|---|
| Captured command output | Text/JSON reports retain complete subprocess stdout/stderr. These can contain hostnames, process names, paths, or network details. Keep reports root/user-private and sanitize before sharing. | Documented; local file modes tested |
| Firewall/SELinux | The repository does not apply the reviewed policy automatically. Confirm actual interfaces, zones, existing broad service entries, approved CIDRs, listeners, labels, and AVCs on RHEL before making changes. | RHEL review NOT RUN |
| Storage | Manual commands in the storage runbook can destroy data if the operator chooses the wrong device. Positively identify the disposable disk and require exact-path confirmation; stop on ambiguity. | No automated destructive path; RHEL disk acceptance NOT RUN |
| Identity and ACLs | Existing primary-group conflicts and foreign sudoers content are guarded, but final access parity requires target positive/negative tests and inspection of ACLs/user data. | Fixture tests passed; target review NOT RUN |
| Backup retention | Retention removes expired matching ELSM archives and checksum sidecars from the canonical destination. Preserve a separate backup before any target retention test; validate actual restore separately. | Fixture tests passed; target retention/restore NOT RUN |
| Remote exposure | Local listener/firewall output cannot establish network reachability or source restrictions from a client. | Second-host acceptance NOT RUN |

## Review outcome

No automatic deployment or remediation is approved by this review. The automation CLI is suitable for local test orchestration and safe reporting, not as a full deployment orchestrator. Full RHEL 9.6 acceptance remains NOT RUN; follow [the acceptance checklist](../tests/manual/acceptance-checklist.md) and record actual sanitized evidence.
