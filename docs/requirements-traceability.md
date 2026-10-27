# Requirements traceability

This matrix maps the canonical requirements in `MASTER_SPEC.md` to the current implementation and evidence. `PASS (local)` means the specified local test actually ran; it does not mean target-RHEL acceptance. No target deployment or second VM is available in this evidence set.

| ID | Requirement | Implementation | Automated/manual verification | Current status |
|---|---|---|---|---|
| FR-01 | Defined local users and groups | Part 02 `provision-identities`; accounts are created without passwords and existing primary-group conflicts are refused. | `tests/unit/test-identity-validation.sh`; target `getent`, `id`, and `sudo -l` in Part 02 tests. | PARTIAL: mocked preflight passes; target account state NOT RUN |
| FR-02 | Department directories and ACLs | Part 02 provisioning after `/srv/company` is mounted. | Identity dry-run test; target positive/negative access checks and ACL inspection. | PARTIAL: target permission tests NOT RUN |
| FR-03 | Dedicated LVM/XFS data filesystem | Part 03 provides a read-only validator and operator runbook; destructive provisioning remains manual. | `tests/unit/test-storage-validation.sh`; target `lsblk`, LVM, XFS, and mount checks. | PARTIAL: validation fixtures pass; real disk setup NOT RUN |
| FR-04 | Persistent mounts | Operator-managed fstab/UUID setup in Part 03 runbook. | `findmnt --verify` and post-reboot checklist. | NOT RUN on target |
| FR-05 | Optional NFS export and client test | Part 04 export example and server/client documentation; no automatic firewall/export deployment. | `exportfs` and second-VM client checklist. | OPTIONAL; target/server/client NOT RUN |
| FR-06 | Apache portal | Part 05 static `index.html` and manual package/install/service steps. | `elsm-status` local checks; target `curl`, SELinux label, and remote client acceptance. | PARTIAL: no live target test |
| FR-07 | Firewall and SELinux-aware security | Part 06 read-only audit, reviewed examples, and rollback guidance. No automatic policy mutation. | `elsm-status` lists zones/rules/listeners and verifies available labels; operator compares source CIDRs. | PARTIAL: policy application and remote exposure NOT RUN |
| FR-08 | Scheduled backup and restore | Part 07 backup script, systemd service/timer, configuration example. | `tests/unit/test-backup-workflow.sh` tests archive/checksum/retention/failure/restore in fixtures; target timer/restore checklist. | PASS (local fixture); target schedule and actual XFS restore NOT RUN |
| FR-09 | Health report and status | Part 08 read-only measurements and report/log output. | Threshold and mocked critical-failure tests; target report comparison checklist. | PASS (local tests); target health acceptance NOT RUN |
| FR-10 | Operational logs without secrets | Component logs and automation summary at configured paths; reports restrict file mode. | Automation CLI report permission test and target log review. | PARTIAL: local report mode tested; target log handling NOT RUN |
| FR-11 | Incident runbooks and drills | `docs/incident-drills.md` and component recovery guidance. | Manual drill records required. | DOCUMENTED; completed target drills NOT RUN |
| FR-12 | Reproducible installation/testing/teardown documentation | Root README, per-part guides, operations/test plans, automation guide, and acceptance checklist. | Static checks and documentation review. | PARTIAL: manual deployment; no clean target reproduction recorded |

## Non-functional requirements

| Requirement | Implementation/evidence | Status |
|---|---|---|
| Least privilege and private network | Part 02 ownership/ACLs; Parts 04/06 review controls; no public exposure defaults. | Design documented; target review NOT RUN |
| Reboot reliability | Systemd backup timer, fstab runbook, acceptance checklist. | NOT RUN |
| Maintainable modules and consistent paths | Canonical values in `MASTER_SPEC.md`, per-part ownership, automation config and script inventory. | PARTIAL; existing component scripts own their own runtime config |
| RHEL 9 compatibility | RHEL-specific Bash commands and RHEL target docs; automation CLI uses Python standard library. | Static tests on Ubuntu WSL only; RHEL 9.6 NOT RUN |
| Auditable changes and recovery | Operator workflow, evidence index, manual rollback instructions, JSON/text automation reports. | Local report generation tested; target evidence NOT RUN |
| No destructive automatic storage operation | All format/LVM creation remains manual; `deploy` is plan-only and BLOCKED. | PASS by design review; no destructive path in CLI |

## Automation-interface requirements

| Requirement | Evidence | Status |
|---|---|---|
| CLI test discovery and subprocess output/exit/duration capture | `bin/elsm`, `tests/unit/test_automation_cli.py` | Implemented; unit-covered |
| Failure aggregation, optional tool distinction, JSON report | `bin/elsm`, automation CLI tests | Implemented; ShellCheck/Ansible optional |
| Dry-run/plan and non-destructive deploy gating | `plan` and `deploy --profile lab` | Implemented; `deploy` always BLOCKED pending a safe complete apply interface |
| End-to-end orchestrated deployment | No all-component apply handlers exist; manual steps include destructive and network/security decisions. | NOT IMPLEMENTED; intentionally not claimed |
| Target RHEL, reboot, second-VM integration | Acceptance checklist | NOT RUN; requires lab hardware/access |
