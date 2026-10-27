# Enterprise Linux Server Management & Monitoring System (ELSM)

A reproducible, RHCSA-aligned administration lab for a private RHEL 9 environment. ELSM demonstrates local identity and least-privilege access, LVM/XFS storage, Apache, optional NFS, firewalld/SELinux review, scheduled backups with restore testing, and read-only health reporting.

> **Project type:** Linux System Administration Lab  
> **Platform:** Red Hat Enterprise Linux 9.6  
> **Virtualization:** VMware Workstation  
> **Focus:** Linux administration, Bash automation, security, monitoring, backup, and recovery

This is a **single-server learning lab**, not a production blueprint. It does not provide high availability, centralized identity, public exposure, or a complete enterprise monitoring stack.

## Project Showcase

The following images illustrate ELSM's health reporting, storage verification, Apache interface, and automated test workflows.

**Image authenticity:** Generated showcase images are illustrative mockups, not independent proof of successful deployment. Terminal test screenshots should be interpreted according to the checks they actually show. Use genuine VM screenshots and recorded test results for final acceptance evidence.

### 1. System Health Report

![ELSM System Health Report](docs/evidence/ELSM%20System%20Health%20Report%20Terminal.png)

Illustrates a consolidated view of system information, resource usage, disk usage, service status, and overall health.

### 2. Storage and LVM Verification

![ELSM Storage Verification](docs/evidence/ELSM%20Storage%20Verification%20Dashboard.png)

Illustrates the storage verification workflow involving physical volumes, volume groups, logical volumes, XFS, and the `/srv/company` mount.

### 3. Apache Web Portal

![ELSM Apache Dashboard](docs/evidence/ELSM%20Apache%20Dashboard%20on%20RHEL.png)

Illustrates the ELSM web interface and the Apache-hosted project dashboard.

### 4. RHEL Environment Showcase

![RHEL 9.6 Terminal Showcase](docs/evidence/RHEL%209.6%20Terminal%20System%20Showcase.png)

A visual overview of the RHEL lab environment and administrative workflow.

### 5. Automated Test Evidence

**Backup workflow tests**

![Backup Workflow Tests](docs/evidence/Backup%20Workflow%20Tests%20Passed.png)

**Health threshold tests**

![Health Threshold Tests](docs/evidence/Linux%20Health%20Threshold%20Test%20Results.png)

**Configuration validation tests**

![Configuration Validation Tests](docs/evidence/Linux%20Terminal%20Configuration%20Tests%20Passed.png)

**Shell validation**

![Shell Validation](docs/evidence/Linux%20Terminal%20Shell%20Checks%20Passed.png)

**Storage validation tests**

![Storage Validation](docs/evidence/Storage%20Validation%20Tests%20Passing.png)

These images are intended to document testing workflows. Refer to the test scripts and actual execution results to establish which checks passed in the current repository and on the target VM.

## Features and Architecture

- **Environment preflight:** Read-only discovery of host details, network configuration, disks, mounts, SELinux state, and system services.
- **Identity and access:** Local users, groups, permissions, and least-privilege access procedures.
- **Storage management:** LVM, XFS, logical volumes, and persistent mount configuration using an explicitly identified data disk.
- **Web services:** Apache HTTP Server configuration and local web portal hosting.
- **Optional NFS:** File sharing within a private lab network, including optional second-VM testing.
- **Security verification:** Firewalld and SELinux review with security-focused runbooks.
- **Backup and recovery:** Scheduled local backups and restore-to-temporary-path testing.
- **Health reporting:** Read-only system and service health reports.
- **Testing and automation:** Static checks, unit tests, integration checks, and text/JSON reports.
- **Central CLI:** `bin/elsm` provides test discovery, preflight, validation, status, planning, and reporting workflows.

```text
Trusted administrator
        |
        | SSH (TCP/22)
        v
+-----------------------------------------+
|            RHEL 9 Lab Server            |
|                                         |
|  Local identity and access controls     |
|  Firewalld and SELinux verification     |
|  LVM + XFS: /srv/company                |
|  Apache web portal: HTTP/80             |
|  Optional NFSv4 file sharing            |
|  Scheduled backups and restore testing  |
|  Health reports and system logs         |
+-----------------------------------------+
        |                         |
        | Optional NFSv4          | HTTP
        v                         v
 Second private VM           Private browser
```

This is a logical architecture. Actual network interfaces, IP addresses, and VMware network settings must be discovered and verified before configuration.

See [Architecture](docs/architecture.md), [Network Plan](docs/network-plan.md), and [Automation Guide](docs/automation-guide.md).

## Technology Stack

| Area | Technologies |
|---|---|
| Operating system | Red Hat Enterprise Linux 9 |
| Scripting | Bash, Python 3 |
| Storage | LVM, XFS, mount utilities |
| Service management | systemd |
| Web server | Apache HTTP Server |
| Network file sharing | NFS, optional |
| Security | SELinux, firewalld, Linux permissions |
| Backup | Scheduled archive-based backups and restore verification |
| Testing | Shell tests, Python CLI, integration checks |
| Optional extension | Ansible for limited identity-management tasks |
| Virtualization | VMware Workstation |

## Repository Structure

```text
ELSM/
├── bin/
│   └── elsm
├── config/
├── docs/
│   ├── architecture.md
│   ├── automation-guide.md
│   ├── network-plan.md
│   ├── operations-runbook.md
│   ├── backup-restore-runbook.md
│   ├── storage-runbook.md
│   ├── security-model.md
│   ├── security-review.md
│   ├── test-plan.md
│   ├── troubleshooting.md
│   ├── requirements-traceability.md
│   ├── script-inventory.md
│   └── evidence/
├── parts/
│   ├── part-01-foundation/
│   ├── part-02-identity-access/
│   ├── part-03-storage/
│   ├── part-04-nfs/
│   ├── part-05-web/
│   ├── part-06-security/
│   ├── part-07-backup/
│   ├── part-08-healthcheck/
│   ├── part-09-integration/
│   └── part-10-ansible-extension/
├── scripts/
├── tests/
├── MASTER_SPEC.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Prerequisites

- A disposable RHEL 9 VM with administrative access.
- VMware Workstation or equivalent virtualization software.
- A private or host-only lab network.
- Python 3.9+ and Bash for the local test workflow.
- RHEL repositories or subscriptions where package installation is required.
- A VM snapshot before storage, firewall, or SELinux changes.
- A separate data disk only when testing storage provisioning.

Never assume that example IP addresses or disk device names match the actual environment.

## Quick Start

### 1. Review the documentation

```bash
less MASTER_SPEC.md
less docs/architecture.md
less docs/network-plan.md
less docs/operations-runbook.md
```

Read the project specification before making changes to the target system.

### 2. Inspect the environment

Follow [Part 01 — Foundation](parts/part-01-foundation/README.md) and inspect the environment before planning deployment.

```bash
hostnamectl
ip -br address
lsblk -f
findmnt
getenforce
systemctl --failed
```

These commands inspect the current system; they do not configure the complete project.

### 3. Review the deployment plan

```bash
python3 bin/elsm plan
```

The deployment plan is advisory and does not perform a full-system installation.

### 4. Run the safe test workflow

Run from the repository root:

```bash
python3 bin/elsm all --profile test \
  --report-dir /tmp/elsm-reports \
  --log-file /tmp/elsm-automation/automation.log
```

Review the resulting reports and exit codes. Tests requiring root privileges may be reported as `BLOCKED` when prerequisites are not met. Optional checks requiring unavailable tools may be reported as `NOT RUN`.

See [Tests](tests/README.md) and the [Test Plan](docs/test-plan.md).

### 5. Validate the target RHEL host

```bash
python3 bin/elsm validate
python3 bin/elsm status
```

Follow each component's README and the operations runbook before making configuration changes.

## Deployment Model

ELSM does **not** claim a fully automated, end-to-end deployment.

- Disk selection and formatting require explicit operator review.
- Storage setup must use a positively identified lab disk.
- Identity, service, network, and security changes must follow their component runbooks.
- `bin/elsm deploy --profile lab` is plan-only and reports `BLOCKED` rather than making partial or unsafe changes.
- `tests/integration/elsm-status` is a read-only verification tool, not an installer or remediation tool.
- The optional Ansible extension manages a limited set of identity primitives. It does not deploy the entire ELSM stack.

Never assume `/dev/sdb` is the correct disk. Review the device identity and contents, and explicitly confirm the intended operation before running destructive storage commands.

## Security and Safety

- Keep SELinux enforcing. Investigate access denials instead of disabling SELinux.
- Use firewalld to restrict access to the private lab network.
- Do not expose SSH, HTTP, or NFS to the public internet.
- Do not configure NFS exports with `no_root_squash`.
- Never commit passwords, private keys, real company data, VM images, backup archives, or sensitive logs.
- Test backup restoration in a temporary location; do not automatically overwrite `/srv/company`.
- Review commands before executing them with `sudo` or as root.
- Take a VM snapshot before potentially disruptive configuration changes.

## Testing and Evidence

Use consistent result categories when recording test outcomes.

| Status | Meaning |
|---|---|
| `PASS` | The check ran and met its documented criteria. |
| `FAIL` | The check ran and found a problem. |
| `BLOCKED` | A prerequisite prevented the check from proceeding. |
| `NOT RUN` | The check was not executed. |
| `REVIEW REQUIRED` | Human review is needed before acceptance. |

A passing unit test does not prove that a service is deployed correctly on RHEL. Record target-VM acceptance separately, including storage mounts, Apache responses, NFS client access, backup restoration, and reboot validation.

Keep evidence free of credentials and sensitive operational data.

## Project Status

The repository contains the project implementation, documentation, scripts, and verification workflows. **Full system acceptance must be established on the actual target VM.** Any component that has not passed its on-host checks must remain documented as incomplete or blocked.

Use the following documents to review project readiness:

- [Requirements Traceability](docs/requirements-traceability.md)
- [Script Inventory](docs/script-inventory.md)
- [Security Review](docs/security-review.md)
- [Operations Runbook](docs/operations-runbook.md)
- [Test Plan](docs/test-plan.md)
- [Evidence Index](docs/evidence/evidence-index.md)

## Learning Objectives

This project provides practical experience with:

- RHEL administration and systemd services
- Local users, groups, permissions, and sudo
- LVM, XFS, and persistent mounts
- Apache and optional NFS configuration
- SELinux and firewalld verification
- Bash automation, logging, validation, and exit codes
- Backup and recovery testing
- System health reporting and troubleshooting
- Test documentation and evidence-based verification

## License

This repository includes a `LICENSE` file. Review it before redistributing the project or incorporating its code into other work.
