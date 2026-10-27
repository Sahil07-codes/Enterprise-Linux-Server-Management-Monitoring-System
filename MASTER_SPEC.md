# Enterprise Linux Server Management & Monitoring System
## Master Project Specification, Implementation Guide, and Parallel-Work Contract

**Document version:** 1.0  
**Status:** Baseline specification  
**Target platform:** Red Hat Enterprise Linux (RHEL) 9.x; RHEL 10 may be used after validating package and command differences  
**Lab environment:** VMware Workstation or equivalent  
**Primary purpose:** RHCSA-aligned hands-on learning and an industry-relevant Linux System Administrator portfolio project  
**Project style:** Infrastructure lab, configuration-as-code where practical, Bash automation, reproducible runbooks, and evidence-based testing

---

## 0. How to use this document

This is the single source of truth for the project. Read it before implementing any component. If multiple people or coding agents work on different parts, they must follow the shared contracts in Sections 4–7 and the part-specific instructions in Section 12.

### Mandatory rules for every contributor

1. **Do not invent or change shared names, paths, users, groups, ports, IP addresses, service names, file formats, exit codes, or interfaces.** Use the canonical values in this document.
2. **Do not configure the same resource in two parts.** Each part has a defined scope and ownership.
3. **Do not silently change the architecture.** Propose a change first, document its reason, and update this master specification before implementation.
4. **Prefer native RHEL administration tools** for RHCSA learning: `dnf`, `systemctl`, `firewalld`, SELinux tools, `useradd`, `groupadd`, `chmod`, `setfacl`, `LVM`, `XFS`, `mount`, `journalctl`, `ss`, `nmcli`, `tar`, `rsync` if installed, and Bash.
5. **Never assume a command or package is present.** Check the RHEL version, repositories, and package availability. Record any version-specific difference.
6. **All scripts must be safe to rerun** where feasible. They must validate inputs, log meaningful messages, return non-zero on failure, avoid destructive defaults, and never expose secrets.
7. **Do not use real company data, real credentials, or public exposure.** This is a private lab. Do not expose SSH, NFS, or the web service to the public internet.
8. **Use placeholders only where explicitly marked.** Do not leave undocumented placeholders in final deliverables.
9. **Every component must include verification and rollback/recovery instructions.**
10. **No component is complete until its acceptance criteria and tests are documented and pass.**
11. **If two parts appear to conflict, the master specification wins.** If the master is ambiguous, stop and raise the ambiguity rather than choosing independently.
12. **Do not put secrets, private SSH keys, host-specific tokens, or raw sensitive logs in Git.**

### Project outcomes

At completion, the repository should let a reviewer:
- understand the architecture and security boundaries;
- reproduce the lab on a fresh RHEL VM;
- provision users and department access;
- configure storage and network file sharing;
- host a simple internal web portal;
- schedule and verify backups;
- inspect system health and service status;
- troubleshoot deliberately introduced failures;
- run tests and view evidence;
- understand what is RHCSA practice versus an optional advanced extension.

---

## 1. Executive summary

Build a simulated small-company Linux environment on RHEL. The server will provide:
- centralized local user and group administration;
- department-scoped shared directories with Linux permissions and ACLs;
- a separate data volume using LVM and XFS, mounted persistently;
- an NFS export for a second lab VM when available;
- an Apache-hosted internal status page;
- host firewall and SELinux configuration;
- automated file backups with retention and restore testing;
- a health-check report and log-based alerts;
- a documented incident-response exercise;
- a Git repository containing scripts, configuration templates, tests, diagrams, and runbooks.

The project deliberately starts as a **single-server baseline**. A second client VM is optional for NFS and remote backup testing. The design does not claim high availability, production-grade centralized identity, or enterprise monitoring. Those can be future extensions.

### Success definition

The project is successful when a fresh lab can be configured using the documentation; all required services survive reboot; only intended network traffic is allowed; department permissions are tested; backups can be restored; health checks produce actionable output; and the documented failure drills can be diagnosed and recovered.

---

## 2. Goals, non-goals, and scope

### 2.1 Goals

- Practice core RHCSA-style administration on RHEL.
- Apply least privilege and explicit network access.
- Automate repeatable maintenance using Bash and systemd timers or cron.
- Use version control and a reviewable directory structure.
- Demonstrate fault isolation and recovery, not merely installation.
- Make independent work possible through strict ownership and interface contracts.

### 2.2 Non-goals for the baseline

The baseline does **not** include:
- public cloud deployment;
- public internet exposure;
- Kubernetes, containers, or a complex web application;
- a database-backed application;
- a GUI administration dashboard;
- centralized identity such as FreeIPA/Active Directory;
- a full SIEM, Prometheus/Grafana stack, or enterprise alerting service;
- automatic remediation of every detected issue;
- production SLA or compliance claims;
- destructive storage changes to the VM's existing operating-system disk.

### 2.3 Optional future extensions

These must not be mixed into baseline work without approval:
- Ansible automation;
- a second NFS/backup server;
- HTTPS with a lab certificate authority;
- Prometheus/node_exporter/Grafana;
- auditd rules and audit report;
- centralized identity;
- SELinux custom policy modules;
- a separate reverse proxy;
- CI checks for shell scripts;
- disaster recovery on a clean replacement VM.

---

## 3. Requirements

### 3.1 Functional requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| FR-01 | Create the defined local groups and users | `getent passwd`, `getent group`, documented test output |
| FR-02 | Apply department-specific shared directory access | Positive and negative access tests for each role |
| FR-03 | Configure a dedicated data filesystem using LVM and XFS | `lsblk`, `pvs`, `vgs`, `lvs`, `findmnt`, reboot test |
| FR-04 | Mount required filesystems persistently | `findmnt --verify` or equivalent validation and reboot test |
| FR-05 | Configure NFS export for the lab subnet when the optional client exists | `exportfs -v`, client mount and access tests |
| FR-06 | Host a local intranet status page using Apache | `curl` from server and permitted client |
| FR-07 | Apply firewall rules and SELinux-aware configuration | `firewall-cmd --list-all`, SELinux status/context checks |
| FR-08 | Back up approved data on a schedule | timer/job status, log, archive listing and checksum/restore test |
| FR-09 | Generate a health report for disk, memory, CPU load, and managed services | sample report with timestamp and explicit status |
| FR-10 | Record operational logs without storing secrets | log review and permissions test |
| FR-11 | Provide incident runbooks and recovery drills | completed test record for each drill |
| FR-12 | Document installation, configuration, testing, and teardown | a new reviewer can follow the repository without oral guidance |

### 3.2 Non-functional requirements

- **Security:** least privilege; no passwordless sudo for routine users; no public exposure; SELinux remains enforcing unless a documented diagnostic test temporarily requires otherwise.
- **Reliability:** configuration survives reboot; scripts fail clearly; backup restore is tested.
- **Maintainability:** consistent naming, small modules, readable shell, centralized configuration, and documented interfaces.
- **Portability:** target RHEL 9; note and test any RHEL 10 differences.
- **Auditability:** every change has a reason, validation steps, and a way to undo it.
- **Resource efficiency:** lab should run on a modest VM; optional second VM is not mandatory for the core path.
- **Safety:** storage operations are performed only on clearly identified additional virtual disks.

### 3.3 Constraints and assumptions

- The project owner has administrative access to a disposable RHEL VM.
- RHEL subscriptions or repositories are available where required.
- Commands may vary slightly across RHEL minor releases.
- Example addresses are documentation-only and must be checked against the actual isolated lab network before use.
- The system uses local accounts; it does not pretend to implement enterprise single sign-on.
- A VM snapshot is taken before storage, firewall, or SELinux changes.

---

## 4. Canonical architecture

### 4.1 Logical topology

```text
Administrator workstation
        |
        | SSH (TCP/22), from trusted lab host only
        v
+------------------------------------------------------+
| RHEL Main Server                                     |
|                                                      |
|  Local accounts/groups       Apache intranet :80     |
|  SSH + sudo                  Health report scripts   |
|  firewalld + SELinux         Backup scheduler        |
|  LVM + XFS data volume       Logs + runbooks         |
|  Department directories     Optional NFS export     |
+------------------------------------------------------+
        |                                      |
        | NFS (TCP/UDP as configured)           | HTTP TCP/80
        v                                      v
 Optional RHEL Client VM                 Browser/curl client
 (NFS mount + restore test)              on isolated lab LAN
```

The diagram is logical. Actual routing and adapter mode depend on the local VMware network configuration. Prefer a host-only or private LAN for the lab. Do not use bridged/public exposure unless there is a specific, reviewed reason.

### 4.2 Suggested VM sizing

| Resource | Main server baseline | Optional client |
|---|---:|---:|
| vCPU | 2 | 1–2 |
| RAM | 2–4 GB | 1–2 GB |
| OS disk | 25–40 GB | 15–25 GB |
| Additional data disk | 8–20 GB | Not required |
| Network | Private/host-only lab LAN | Same private/host-only LAN |

These are lab recommendations, not production sizing guidance.

### 4.3 Canonical host identity and network plan

| Item | Canonical value | Rule |
|---|---|---|
| Project name | Enterprise Linux Server Management & Monitoring System | Use consistently in docs |
| Main hostname | `rhel-srv01` | Do not rename in individual parts |
| Optional client hostname | `rhel-cli01` | Only when second VM exists |
| Example server IP | `192.168.56.10/24` | Confirm actual host-only subnet first |
| Example client IP | `192.168.56.20/24` | Confirm no collision |
| Example lab subnet | `192.168.56.0/24` | Documentation default only |
| SSH port | TCP/22 | Do not change without approval |
| HTTP port | TCP/80 | Internal lab only |
| NFS | NFSv4 preferred; TCP/2049 where supported by chosen configuration | Verify actual service configuration |
| Time zone | Use the VM's chosen local time zone; document it | Do not hard-code in scripts |
| DNS | `/etc/hosts` may be used for the isolated lab | Document every entry |

**Important:** VMware host-only networks can use a different subnet. Before applying IP or firewall configuration, inspect the VM network and choose one consistent subnet. Update this master file before implementation if the canonical example subnet must change. Do not assume the example IP is safe to apply.

### 4.4 Service and ownership map

| Component | Primary owner | Resource boundary |
|---|---|---|
| Host baseline and repository skeleton | Part 01 | OS identity, network plan, documentation skeleton |
| Users, groups, SSH, sudo, shared directory permissions | Part 02 | Accounts and access policy |
| LVM, XFS, persistent mounts | Part 03 | Only added data disk and `/srv/company` |
| NFS export and optional client mount | Part 04 | NFS configuration and `/srv/company` export declaration; coordinate with Part 03 |
| Apache intranet | Part 05 | Apache configuration and `/var/www/html` content |
| Firewall and SELinux hardening | Part 06 | Network exposure policy and SELinux validation; must review other parts |
| Backup scripts and schedule | Part 07 | `/usr/local/sbin/elsm-backup`, backup destination, timer, backup logs |
| Health checks and report | Part 08 | `/usr/local/sbin/elsm-healthcheck`, report and monitoring logs |
| Integration, tests, incidents, final evidence | Part 09 | Cross-component testing and final documentation |
| Optional Ansible extension | Part 10 | Ansible playbooks only; no baseline ownership changes |

Ownership means the named part authors the resource and its primary documentation. Other parts may declare a dependency but must not independently create or modify that resource.

---

## 5. Canonical names, paths, accounts, and interfaces

These values are the cross-part contract. If a value changes, it must be changed here first and then propagated to all dependent parts in one reviewed change.

### 5.1 Groups and users

Use these fictional lab identities. Set passwords interactively during provisioning; never commit passwords.

| Group | Purpose | Members |
|---|---|---|
| `linuxadmins` | Privileged system administrators | `labadmin` |
| `developers` | Development department | `dev01`, `dev02` |
| `hrteam` | HR department | `hr01` |
| `ops team` is **not** a valid group name for this project | Avoid spaces in group names | Use `ops` instead |
| `ops` | Operations department | `ops01` |
| `projectreaders` | Read-only shared project access | `auditor01` |

| User | Primary group | Supplementary groups | Sudo |
|---|---|---|---|
| `labadmin` | `linuxadmins` | none required | Administrative sudo access |
| `dev01` | `developers` | `projectreaders` | No |
| `dev02` | `developers` | `projectreaders` | No |
| `hr01` | `hrteam` | none | No |
| `ops01` | `ops` | `projectreaders` | No |
| `auditor01` | `projectreaders` | none | No |

Do not use the real names of people. If an account is not needed in a particular test, it still remains part of the documented access model. Administrative sudo should be granted using a dedicated, clearly documented rule or the distribution's established admin group mechanism after checking the default RHEL policy. Do not overwrite the entire `/etc/sudoers` file.

### 5.2 Canonical paths

| Path | Purpose | Owner |
|---|---|---|
| `/srv/company` | Root of company data on dedicated XFS filesystem | Part 03 |
| `/srv/company/development` | Developer shared directory | Part 02, on filesystem supplied by Part 03 |
| `/srv/company/hr` | HR shared directory | Part 02 |
| `/srv/company/operations` | Operations shared directory | Part 02 |
| `/srv/company/projects` | Cross-department read-only project material | Part 02 |
| `/srv/company/.recycle` | Optional controlled recovery area; not mandatory in baseline | Requires approval |
| `/var/backups/elsm` | Local backup destination | Part 07 |
| `/var/log/elsm` | Project automation logs | Part 07 creates base path; Part 08 may use a distinct file in it |
| `/var/lib/elsm` | State files if needed; must be documented per script | Each script must declare its file |
| `/var/www/html/index.html` | Internal portal page | Part 05 |
| `/usr/local/sbin/elsm-backup` | Backup entry point | Part 07 |
| `/usr/local/sbin/elsm-healthcheck` | Health check entry point | Part 08 |
| `/etc/elsm/backup.conf` | Backup settings | Part 07 |
| `/etc/elsm/healthcheck.conf` | Health check settings | Part 08 |
| `/etc/exports.d/elsm.exports` | NFS export declaration, if using exports.d | Part 04 |
| `/etc/elsm/` | Project configuration directory | Parts 07 and 08 create their own files; use safe directory creation |
| `/var/log/elsm/backup.log` | Backup execution log | Part 07 |
| `/var/log/elsm/healthcheck.log` | Health check log | Part 08 |
| `/var/lib/elsm/health/latest.txt` | Latest health report | Part 08 |

### 5.3 File permissions and department access contract

The implementation must use a least-privilege model. Recommended policy:

- `/srv/company` is root-owned and not writable by all users.
- Each department directory is owned by `root` and its department group, with group write only for that department, using setgid where appropriate.
- Use default ACLs only where needed and document them.
- `development`: members of `developers` can read/write; `projectreaders` can read if explicitly required; unrelated groups have no access.
- `hr`: only `hrteam` and administrators can access; no cross-department reader access.
- `operations`: members of `ops` can read/write; project readers may read only if needed.
- `projects`: members of `developers`, `ops`, and `projectreaders` can read; only an explicitly designated publishing group may write. If no publisher group is added, `root` is the publisher.
- `labadmin` can administer files via sudo but ordinary users should not share its credentials.

The implementation must include actual `sudo -u USER` positive and negative tests. Do not infer access solely from `ls -l`; inspect ACLs with `getfacl`.

### 5.4 Script contract

All project scripts must follow this common contract:

- Bash shebang: `#!/usr/bin/env bash`
- use `set -Eeuo pipefail` unless a documented reason makes it inappropriate;
- quote variable expansions;
- validate required commands, configuration files, and paths;
- write clear timestamped log lines;
- write errors to stderr and return non-zero on failure;
- do not echo passwords, tokens, or private data;
- support a safe read-only or dry-run mode where destructive actions are possible;
- do not recursively delete arbitrary paths from config without strict validation;
- use `umask 077` for sensitive backup files and state;
- use `flock` or another documented lock to prevent concurrent execution when appropriate;
- use absolute paths for system-managed scripts;
- include `--help` or a usage block;
- document exit codes in the script header and README.

Suggested exit codes, unless a script has a justified documented alternative:
- `0`: success;
- `1`: general failure;
- `2`: invalid usage or configuration;
- `3`: required dependency missing;
- `4`: operation partially failed or validation failed.

### 5.5 Logs and reports

- Log timestamps must be ISO-like and unambiguous, e.g. `2026-10-27T10:30:00+05:30`.
- Use the system's local timezone consistently; do not hard-code a timezone in the script.
- Avoid logging entire environment variables or sensitive file contents.
- Health report should state `OK`, `WARN`, or `CRITICAL` per check and include a generation timestamp.
- Reports must distinguish observed values from thresholds.
- Logs should have documented ownership and permissions.
- Log rotation may use `logrotate` if available; configuration must be validated before enabling.

---

## 6. Repository structure contract

The repository root is named `elsm-lab/`.

```text
elsm-lab/
├── README.md
├── MASTER_SPEC.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── requirements.md
│   ├── network-plan.md
│   ├── security-model.md
│   ├── operations-runbook.md
│   ├── troubleshooting.md
│   ├── test-plan.md
│   ├── incident-drills.md
│   ├── decisions/
│   │   └── ADR-0001-baseline-architecture.md
│   └── evidence/
│       ├── README.md
│       └── evidence-index.md
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
│   ├── README.md
│   └── lib/
│       └── common.sh
├── tests/
│   ├── README.md
│   ├── unit/
│   ├── integration/
│   └── manual/
└── evidence/
    └── .gitkeep
```

### Repository rules

- Every part may create files only inside its own `parts/part-XX-*` directory and its explicitly assigned top-level documentation paths.
- A part must not create a competing `README.md` at repository root.
- The integration owner merges files into the final shared locations.
- Shared helper code in `scripts/lib/common.sh` is owned by Part 01; other parts must not edit it independently.
- Scripts may be delivered within their part directory first, then integrated into their canonical system path during deployment.
- Do not commit generated backup archives, VM images, secrets, private keys, or unfiltered logs.
- `.gitignore` must exclude secrets, local environment files, backup archives, and generated reports while keeping safe sample configuration templates.
- All configuration templates must use `.example` suffixes where they contain placeholders.

---

## 7. Dependency and conflict control

### 7.1 Dependency graph

```text
Part 01 Foundation
  ├── Part 02 Identity & Access
  ├── Part 03 Storage
  │     └── Part 04 NFS
  ├── Part 05 Web
  ├── Part 06 Security (reviews all services)
  ├── Part 07 Backup (depends on Part 03 paths)
  ├── Part 08 Health Check (checks service/storage from other parts)
  └── Part 09 Integration (depends on all baseline parts)

Part 10 Ansible Extension depends on a stable, tested baseline.
```

Part 02 and Part 03 can be developed in parallel because Part 02 owns directory policy while Part 03 owns the filesystem and mount. Part 04 must coordinate the export path with Part 03 but must not format or mount the server's data disk. Part 06 is a cross-cutting review and should not independently rewrite every service configuration. It proposes the minimum required changes to the owning part. Part 09 is the final integrator and may not silently change component behavior.

### 7.2 Interface freeze

Before parallel implementation begins, freeze:
- hostnames, subnet, IP plan;
- user/group names;
- shared paths and permissions;
- script names, config paths, report formats and exit codes;
- service ports;
- repository layout;
- ownership boundaries.

Any change requires a change request containing:
1. proposed change;
2. reason;
3. affected parts and paths;
4. compatibility impact;
5. test updates;
6. approval by the project owner;
7. update to this master document before code changes are merged.

### 7.3 Parallel work protocol

Each contributor must return:
1. a list of files created or changed;
2. assumptions and dependencies;
3. exact installation/configuration commands;
4. verification commands and expected output;
5. rollback procedure;
6. known limitations;
7. acceptance-test results;
8. any proposed master-spec changes (not applied silently).

No contributor may claim another part's tests passed unless they actually ran them or clearly label the result as unverified.

---

## 8. Environment setup and safety checklist

### 8.1 Before changing the VM

Run and record:
```bash
cat /etc/redhat-release
uname -r
hostnamectl
ip -br address
ip route
nmcli connection show
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
df -hT
getenforce
systemctl --failed
```

Create a VM snapshot. Confirm which disk is the OS disk and which disk is the added data disk. **Never copy a sample `/dev/sdb` command without verifying the device.** Disk names vary.

### 8.2 Package and repository readiness

Check repository status before installing packages:
```bash
sudo dnf repolist
sudo dnf makecache
```

Typical packages may include `httpd`, `nfs-utils`, `acl`, `policycoreutils-python-utils`, `lvm2`, `xfsprogs`, and `rsync`. Package availability depends on the RHEL release and enabled repositories. Install only what is required and record package names in the relevant part's README.

### 8.3 Baseline health and recovery

- Confirm administrative access in the VM console before changing SSH/firewall.
- Keep a second console session open when changing networking or SSH.
- Save copies of configuration files before edits.
- Use `ss -tulpn`, `firewall-cmd`, `getenforce`, `ausearch` if available, and `journalctl` to verify the real state.
- Do not disable SELinux as a shortcut. Diagnose labels, booleans, ports, and AVC denials first.
- Do not run a filesystem format command unless the selected disk is confirmed as the added disposable data disk.
- Use a snapshot before LVM, mount, NFS, firewall, and SELinux changes.

---

## 9. Detailed design

### 9.1 Foundation and host baseline

Part 01 records the OS version, hostname, IP plan, repository structure, shared helper conventions, evidence approach, and setup checks. It must not hard-code a network address into scripts without a configuration mechanism. Host-specific network configuration is applied manually or through a clearly marked optional script after confirming the lab network.

### 9.2 Identity and access

Part 02 provisions the groups and users in Section 5.1. It must:
- check whether each group/user already exists;
- avoid duplicating entries;
- not assign a shared default password;
- provide a secure interactive password setup procedure;
- configure admin privileges using a separate file under `/etc/sudoers.d/` with validation via `visudo -cf`;
- configure SSH key authentication as a documented optional hardening step;
- not lock out the administrator before testing an alternate session;
- create directories only after `/srv/company` is mounted, or provide a safe staged process that checks the mount to avoid accidentally filling the root filesystem.

### 9.3 Storage

Part 03 uses a clearly identified additional virtual disk. The exact device is an environment-specific variable and must never be blindly assumed. Recommended target:
- LVM physical volume and volume group: `vg_elsm`;
- logical volume: `lv_company`;
- filesystem: XFS;
- mount point: `/srv/company`;
- persistent mount entry identified by filesystem UUID, not a fragile `/dev/sdX` name.

Recommended initial filesystem size is chosen based on the added disk; do not use a fixed size if it exceeds the available capacity. The implementation must include `pvs`, `vgs`, `lvs`, `blkid`, `findmnt`, `df -hT`, and reboot verification. If a device already contains data or signatures, stop and ask for confirmation rather than wiping it.

### 9.4 NFS

Part 04 exports `/srv/company` or a more restricted approved subdirectory to the lab subnet. NFS must not be exposed publicly. Use NFSv4 where practical. Export options must be explained; do not use `no_root_squash`. Start with least privilege and read/write access only where the use case requires it. Confirm the actual export syntax, firewall services, SELinux booleans/labels, and client mount behavior for the chosen RHEL release. If no second VM is available, document server-side configuration and mark client integration as pending rather than claiming end-to-end validation.

### 9.5 Apache intranet

Part 05 installs Apache and serves a simple static status portal from `/var/www/html/index.html`. It is an internal project overview, not a real-time monitoring dashboard. The page may show:
- project title;
- server hostname and environment label, if inserted safely;
- service links or health-report instructions;
- documentation links;
- a warning that the page is for an isolated lab only.

Do not embed secrets, raw logs, private IP details beyond the lab's intended audience, or system command output in HTML. Apache should be managed by systemd. Configure SELinux-compatible content placement and use the standard HTTP service/port. Do not expose a write-enabled upload endpoint.

### 9.6 Security

Part 06 reviews the combined system:
- SSH access source and authentication;
- sudo rules;
- firewalld zone and allowed services/ports;
- SELinux enforcing mode and relevant labels/booleans;
- service permissions;
- NFS export scope;
- backup/report permissions;
- file permissions and ACLs;
- absence of secrets in Git;
- service status and listening sockets.

Part 06 should create a security checklist and recommendations. It must ask the owning part to make service-specific changes rather than duplicating or overwriting its config. Any temporary test that changes SELinux mode must be tightly controlled, time-limited, and reverted immediately; baseline acceptance requires enforcing mode.

### 9.7 Backup design

Part 07 creates a backup script and a configuration file. The script backs up approved company data under `/srv/company` to `/var/backups/elsm`. The backup archive must:
- have a predictable timestamped name;
- preserve ownership/permissions where supported;
- avoid including the backup destination inside its own source;
- handle a missing source or unmounted filesystem as a failure;
- create a manifest or checksum;
- apply a configurable retention period, default 7 days for the lab;
- log start, success/failure, archive path, size, and duration;
- use a lock to prevent concurrent runs;
- never delete files outside `/var/backups/elsm`;
- provide a restore procedure to a temporary directory first, not overwrite production paths automatically.

Preferred schedule: a systemd service plus timer. A cron alternative is acceptable only if documented. The project must test both backup creation and restoration of a sample file. A successful archive creation alone is not proof of recoverability.

Suggested config keys:
```bash
BACKUP_SOURCE="/srv/company"
BACKUP_DEST="/var/backups/elsm"
RETENTION_DAYS="7"
LOG_FILE="/var/log/elsm/backup.log"
```
Validate paths and numeric retention values. Treat these as defaults, not blindly sourced trusted code; if a shell config is sourced, permissions and validation must be strict.

### 9.8 Health-check design

Part 08 creates a read-only health-check script. It must not automatically restart services or delete files in the baseline. It checks:
- filesystem usage for `/` and `/srv/company` if mounted;
- memory availability;
- system load (report values and a simple configurable threshold);
- status of `sshd`, `httpd`, and `nfs-server` only when NFS is configured; absent optional service should be `SKIP`, not a false failure;
- systemd failed units;
- existence and freshness of the latest backup, if Part 07 is installed;
- SELinux mode and firewall service status;
- whether `/srv/company` is a mount point.

Default disk thresholds:
- `WARN` at 80% usage;
- `CRITICAL` at 90% usage.
These thresholds are for the lab and configurable. Report values must be derived from actual system commands, not invented. The script must not print a global `OK` if a required check is `CRITICAL`. Exit codes must follow Section 5.4; use `1` for any critical result unless the script documents and tests a more specific scheme. Save the latest report at `/var/lib/elsm/health/latest.txt` and append operational logs to `/var/log/elsm/healthcheck.log`.

### 9.9 Incident drills

Part 09 must document controlled drills. Examples:
1. stop Apache and detect/recover it;
2. introduce a harmless permissions mismatch in a test directory and diagnose it;
3. create a temporary test file to exercise backup/restore;
4. fill a small test filesystem only if safe and disposable, or simulate a threshold in test mode;
5. make an invalid test configuration in a copy, confirm validation catches it, then restore;
6. diagnose an SELinux denial using logs without disabling SELinux;
7. simulate a missing optional NFS service and confirm the health report says `SKIP`.

Do not deliberately break SSH/network access in a way that removes console access. Do not fill the OS filesystem. Every drill must have setup, expected symptom, diagnosis, remediation, verification, and cleanup.

---

## 10. Common verification command catalogue

Use the relevant subset in each part's test plan. Commands are examples; ensure the installed RHEL version supports the option.

### Host and network
```bash
cat /etc/redhat-release
hostnamectl
ip -br address
ip route
nmcli device status
ss -tulpn
ping -c 3 <LAB_PEER_IP>
```

### Users, groups, permissions
```bash
getent passwd labadmin
getent group developers
id dev01
sudo -l -U labadmin
namei -l /srv/company/development
getfacl /srv/company/development
sudo -u dev01 touch /srv/company/development/test-from-dev01.txt
sudo -u hr01 cat /srv/company/hr/sample.txt
```
For negative tests, use a harmless test file and expect an access-denied result. Never use a sensitive HR file for cross-department testing.

### Storage
```bash
lsblk -f
sudo pvs
sudo vgs
sudo lvs
sudo blkid
findmnt /srv/company
df -hT /srv/company
sudo findmnt --verify
```

### Services, firewall, SELinux
```bash
systemctl status httpd
systemctl is-enabled httpd
systemctl --failed
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
getenforce
sestatus
sudo ausearch -m AVC -ts recent
journalctl -u httpd --since "30 minutes ago"
```

### NFS
```bash
sudo exportfs -v
systemctl status nfs-server
showmount -e rhel-srv01
findmnt -t nfs,nfs4
```
`showmount` behavior depends on NFS version/configuration. Use the actual mount and file-access test as the primary client validation.

### Backup and health
```bash
sudo systemctl list-timers --all
sudo systemctl status elsm-backup.timer
sudo journalctl -u elsm-backup.service
sudo /usr/local/sbin/elsm-backup --help
sudo /usr/local/sbin/elsm-healthcheck --help
sudo cat /var/lib/elsm/health/latest.txt
sudo tail -n 100 /var/log/elsm/backup.log
sudo tail -n 100 /var/log/elsm/healthcheck.log
```

---

## 11. Test and acceptance strategy

### 11.1 Test layers

1. **Static review:** shell syntax, quoting, permissions, secrets scan, consistency with canonical names.
2. **Component tests:** each part's local checks and error handling.
3. **Integration tests:** dependencies work together on the target VM.
4. **Reboot tests:** persistent mounts, enabled services, timers, firewall and SELinux state.
5. **Negative tests:** unauthorized access is denied, missing config fails clearly, unmounted data volume prevents backup.
6. **Recovery tests:** restore sample file, recover failed service, clean up test artifacts.
7. **Documentation test:** another person follows the instructions without verbal guidance.

### 11.2 Shell validation

For each shell script:
```bash
bash -n path/to/script
shellcheck path/to/script
```
Install ShellCheck only if available and appropriate for the environment; otherwise record it as a local development tool. Do not claim lint passed if it was not run.

### 11.3 Minimum acceptance gates

- [ ] Hostname and network plan documented and verified.
- [ ] Added data disk positively identified before formatting.
- [ ] `/srv/company` mounted persistently on XFS.
- [ ] User/group membership matches the contract.
- [ ] Department access positive and negative tests pass.
- [ ] Apache page loads from the permitted lab network.
- [ ] Firewall only allows intended services from the intended scope.
- [ ] SELinux remains enforcing and services function with appropriate contexts/policies.
- [ ] NFS client test passes, or is explicitly marked not run due to missing client VM.
- [ ] Backup job completes, manifest/checksum is created, and restore test passes.
- [ ] Health report contains real measurements and correct status.
- [ ] At least five incident drills are documented; each completed drill has evidence.
- [ ] Reboot tests pass.
- [ ] Repository contains no secrets, VM images, or backup archives.
- [ ] Root README gives a clean start-to-finish setup sequence.

---

## 12. Independent implementation parts and prompts

### How to use these prompts

Give each prompt to a separate developer or coding agent together with this master document. Tell the agent to treat this document as authoritative. Each part prompt defines its own scope and forbids modifying resources owned by other parts.

The parts are independent in **implementation work**, not all independent at runtime. Dependencies must be respected during deployment. Parts 02, 03, 05, 07, and 08 can be authored in parallel against the contracts. Part 04 depends on the storage path contract; Part 06 reviews the assembled configuration; Part 09 integrates everything; Part 10 is optional and starts only after the baseline is stable.

---

### Part 01 — Foundation, repository, environment preflight, and shared conventions

**Purpose:** Establish a consistent project skeleton and safe environment-discovery workflow.

**Owns:**
- `parts/part-01-foundation/`
- root `.gitignore` proposal;
- `docs/architecture.md`, `docs/network-plan.md`, `docs/decisions/ADR-0001-baseline-architecture.md`;
- shared `scripts/lib/common.sh` proposal, only after its interface is reviewed.

**Must deliver:**
- repository skeleton matching Section 6;
- root README draft with project summary and setup prerequisites;
- preflight script that reports RHEL version, hostname, addresses, routes, disks, mount points, SELinux state, failed units, and repository readiness;
- no automatic disk formatting, network changes, firewall changes, or destructive operations;
- a clear evidence-index template;
- a change-control template.

**Must not:**
- create users/groups;
- format or mount disks;
- configure Apache/NFS;
- alter firewall or SELinux settings;
- implement backup or health-check behavior owned by other parts.

**Acceptance criteria:**
- preflight script is read-only;
- script validates dependencies and reports missing commands;
- repository layout matches the master;
- `.gitignore` excludes secrets, archives, VM artifacts, and generated private logs;
- no real credentials or host-specific assumptions are committed.

**Prompt to give the contributor:**

> You are implementing Part 01 of the “Enterprise Linux Server Management & Monitoring System” project. Read the entire supplied MASTER_SPEC.md and obey it as the single source of truth. Build only the foundation/repository/preflight deliverables listed under Part 01. Create files only within `parts/part-01-foundation/` plus the specifically assigned shared documentation paths. Do not implement identity, storage, NFS, Apache, firewall/SELinux changes, backup, or health-check features. Provide a read-only Bash preflight script, repository skeleton, architecture/network documentation, ADR-0001, evidence index, and change-request template. Do not assume `/dev/sdb`, a fixed interface name, or a particular subnet is correct; discover and report facts without modifying them. Scripts must use safe Bash practices, clear errors, help/usage, and test instructions. Return a file inventory, exact validation commands, expected output patterns, limitations, and confirmation that no out-of-scope files/resources were changed.

---

### Part 02 — Identity, groups, sudo, SSH, and department access controls

**Purpose:** Implement local identity and access policy using the exact names and paths in Sections 5.1–5.3.

**Owns:**
- `parts/part-02-identity-access/`
- `docs/security-model.md` draft for accounts/filesystem permissions;
- a provisioning script or step-by-step idempotent runbook for users/groups;
- department directory permission/ACL setup script or runbook.

**Must deliver:**
- safe, rerunnable account/group provisioning;
- no hard-coded shared passwords;
- validated sudoers drop-in for `labadmin`;
- access policy for `/srv/company/development`, `/hr`, `/operations`, `/projects`;
- test matrix for allowed and denied access;
- safe handling when `/srv/company` is not mounted;
- a documented SSH key setup procedure and lockout prevention steps.

**Must not:**
- create or format the filesystem;
- configure NFS exports;
- configure Apache;
- change global SSH settings without a documented proposal and a test plan;
- disable SELinux or rewrite the global sudoers file.

**Acceptance criteria:**
- canonical users/groups match exactly;
- rerunning provisioning does not duplicate users/groups or reset passwords;
- `visudo -cf` validates the sudoers drop-in;
- negative access tests confirm unauthorized users cannot read/write;
- HR directory is not readable by `projectreaders`;
- directory setup refuses to proceed if `/srv/company` is not a mounted filesystem, unless a clearly separated dry-run mode is used.

**Prompt:**

> Implement Part 02 only, using the supplied MASTER_SPEC.md as the authoritative contract. Create local users/groups, admin sudo policy, department directories and permissions/ACLs exactly as defined in Sections 5.1–5.3. The storage owner is Part 03: do not format, mount, or create the `/srv/company` filesystem. Before writing company data directories, verify `/srv/company` is actually mounted; do not accidentally create them on the root filesystem. Do not assign shared default passwords or commit credentials. Use safe idempotent Bash or a precise runbook. Include positive and negative `sudo -u USER` tests, ACL verification, rollback instructions, and a file inventory. Do not modify Apache, NFS, firewall, SELinux mode, backup, or monitoring resources. If the master’s ACL policy needs a change, report a proposal instead of silently changing it.

---

### Part 03 — LVM, XFS, persistent storage, and mount validation

**Purpose:** Provision the added disposable virtual disk as a persistent company data volume.

**Owns:**
- `parts/part-03-storage/`
- `docs/storage-runbook.md` proposal;
- storage preflight/validation helpers.

**Must deliver:**
- a preflight checklist to positively identify the added data disk;
- an operator-confirmed LVM + XFS procedure;
- canonical names `vg_elsm`, `lv_company`, mount `/srv/company`;
- persistent UUID-based mount configuration;
- capacity and post-reboot verification;
- safe expansion procedure if spare capacity exists;
- recovery/rollback notes and a warning about destructive operations.

**Must not:**
- assume the data disk is `/dev/sdb`;
- format the OS disk or any disk with unreviewed existing data;
- create department directories or set department ACLs;
- configure NFS, Apache, backups, or monitoring;
- use destructive operations in an unattended script.

**Acceptance criteria:**
- device selection requires explicit confirmation after displaying `lsblk -f`;
- filesystem is XFS;
- mount survives reboot;
- `findmnt`, `df -hT`, `pvs`, `vgs`, and `lvs` confirm expected state;
- an already-mounted or signature-bearing device triggers a safe stop.

**Prompt:**

> Implement Part 03 only. Read MASTER_SPEC.md first. Create a storage runbook and validation helpers for a clearly identified additional virtual disk. The required names are `vg_elsm`, `lv_company`, XFS, and `/srv/company`; persistent mounting must use the filesystem UUID. Never assume the device is `/dev/sdb`, never format automatically, and never wipe a disk with existing signatures or data without explicit operator confirmation. Include exact preflight commands, disk-selection safeguards, creation steps, `fstab` validation, reboot checks, expansion notes, and recovery/rollback guidance. Do not create department directories or change their permissions; Part 02 owns those. Do not configure NFS, Apache, firewall, backup, or monitoring. Return a test checklist and a list of every file created.

---

### Part 04 — NFS server export and optional client integration

**Purpose:** Share an approved company path with the isolated lab client.

**Owns:**
- `parts/part-04-nfs/`
- NFS server/client runbooks;
- `/etc/exports.d/elsm.exports` deployment instructions or template.

**Must deliver:**
- RHEL package and service setup;
- NFSv4-oriented configuration where supported;
- export scope restricted to the actual lab subnet;
- safe export options with rationale;
- client mount/unmount and persistent mount instructions;
- firewall/SELinux requirements handed to Part 06 for review;
- a clear test path when no second VM exists.

**Must not:**
- format/mount the server data disk;
- alter department ACLs;
- use `no_root_squash`;
- open NFS to the public internet;
- independently rewrite firewall or SELinux configuration;
- claim client testing passed if no client exists.

**Acceptance criteria:**
- export path exists and is mounted from the dedicated data filesystem;
- export scope matches the actual private lab subnet;
- `exportfs -v` shows intended options;
- optional client mounts and can perform only permitted operations;
- absence of client VM is explicitly recorded as an incomplete integration test.

**Prompt:**

> Implement Part 04 only, based on MASTER_SPEC.md. Configure NFS sharing for the approved `/srv/company` path or a justified restricted subdirectory, using the actual isolated lab subnet rather than exposing it publicly. Prefer NFSv4 where supported. Never use `no_root_squash`. Verify that `/srv/company` is mounted from the dedicated XFS volume before exporting it. Do not format disks, alter department ACLs, or independently change firewall/SELinux settings; document the exact requirements for Part 06 to review. Provide server and optional client runbooks, export validation, mount/access tests, unmount/rollback steps, and clear status wording if no second VM is available. Return a file inventory and acceptance-test results.

---

### Part 05 — Apache internal portal

**Purpose:** Deploy a simple internal static intranet page using Apache.

**Owns:**
- `parts/part-05-web/`
- static portal HTML/CSS assets;
- Apache deployment and troubleshooting runbook.

**Must deliver:**
- package installation and systemd service instructions;
- simple accessible static page at `/var/www/html/index.html`;
- internal-lab warning;
- `curl` and service verification;
- SELinux-compatible content handling;
- firewall requirement documented for Part 06.

**Must not:**
- build a dynamic app or database;
- embed secrets or raw logs;
- configure the firewall independently;
- disable SELinux;
- modify users, storage, NFS, backup, or health-check scripts.

**Acceptance criteria:**
- Apache starts and is enabled;
- `curl http://localhost/` returns the expected page;
- page contains no secrets;
- service survives reboot;
- the external client test is limited to the private lab network.

**Prompt:**

> Implement Part 05 only, using MASTER_SPEC.md as the contract. Build a small, professional static internal portal served by Apache at `/var/www/html/index.html`. Include the project name, purpose, environment label, documentation/help instructions, and a clear lab-only warning. Provide RHEL package/service commands, `curl` tests, journal troubleshooting, SELinux-aware content guidance, and rollback. Do not create a dynamic application, database, upload feature, or dashboard that claims to show live metrics. Do not alter firewall or SELinux mode; document required HTTP access for Part 06 to review. Do not modify storage, user access, NFS, backup, or monitoring resources. Return all files, validation steps, and test results.

---

### Part 06 — Security hardening review: firewalld, SELinux, SSH, and exposure

**Purpose:** Apply and verify a coherent security policy across the assembled baseline.

**Owns:**
- `parts/part-06-security/`
- `docs/security-model.md` final security review;
- firewall/SELinux checklist and audit report template.

**Must deliver:**
- active-zone and interface discovery;
- an explicit allowlist for required services;
- SSH source restriction suitable for the actual private lab network;
- HTTP access limited to the lab;
- NFS rules only if Part 04 is enabled;
- SELinux enforcing verification and service-specific label/boolean troubleshooting;
- sudo, file permission, listening-port, and secrets review;
- safe rollback plan.

**Must not:**
- blindly flush firewall rules;
- set SELinux to permissive/disabled as a permanent solution;
- overwrite service configurations owned by other parts;
- lock out the only administrator;
- expose the VM publicly.

**Acceptance criteria:**
- intended active zone is documented;
- only required services/ports are enabled for the lab;
- SELinux is enforcing;
- `ss -tulpn`, `firewall-cmd`, and SELinux checks agree with the documented design;
- each required service still works after hardening;
- rollback is documented and tested where safe.

**Prompt:**

> Implement Part 06 as a cross-cutting security review, not as a rewrite of every component. Read MASTER_SPEC.md and inspect the documented requirements from Parts 02–05, 07, and 08. Discover the actual active firewalld zone and network interface before proposing changes. Create a minimal allowlist for SSH and HTTP on the private lab network, adding NFS only if it is enabled. Keep SELinux enforcing; diagnose labels, booleans, ports, and AVC denials instead of disabling it. Do not flush firewall rules, overwrite other parts’ configs, or risk administrator lockout. Produce a security checklist, verification commands, findings with severity, remediation instructions assigned to the owning part, and rollback steps. Any changes to another part’s files must be proposed for that owner to apply. Return evidence and explicitly state which checks were actually executed.

---

### Part 07 — Automated backup and restore

**Purpose:** Create a safe, logged, scheduled backup of company data.

**Owns:**
- `parts/part-07-backup/`
- `/usr/local/sbin/elsm-backup` implementation;
- `/etc/elsm/backup.conf` template and deployment instructions;
- systemd service/timer;
- `/var/backups/elsm` and `/var/log/elsm/backup.log` behavior;
- `docs/backup-restore-runbook.md`.

**Must deliver:**
- config validation;
- source mount check;
- timestamped archive and manifest/checksum;
- retention default 7 days, safely constrained to backup destination;
- lock against overlapping runs;
- systemd service/timer;
- restore-to-temporary-directory instructions;
- sample-file end-to-end restore test.

**Must not:**
- include `/var/backups/elsm` in the source;
- delete paths outside the backup destination;
- auto-restore over the live source;
- store secrets;
- claim a backup is valid without a restore test.

**Acceptance criteria:**
- missing/unmounted source fails non-zero;
- successful backup logs archive path and result;
- archive can be listed and test file restored;
- retention only deletes eligible files within the canonical destination;
- timer is enabled and behavior is documented;
- script is safe to rerun and prevents overlapping execution.

**Prompt:**

> Implement Part 07 only according to MASTER_SPEC.md. Create `/usr/local/sbin/elsm-backup`, a validated `/etc/elsm/backup.conf` template, a systemd service/timer, and a backup/restore runbook. Default source is `/srv/company`, destination `/var/backups/elsm`, retention 7 days, and log `/var/log/elsm/backup.log`. Validate that the source is mounted and the destination is not inside the source. Use timestamped archives, a manifest/checksum, safe permissions, locking, clear logs, and strict validation that retention deletion cannot escape the backup destination. Never automatically overwrite live data during restore; restore to a temporary directory first. Do not modify the storage mount, department ACLs, firewall, Apache, or health-check implementation. Include failure tests, a sample-file restore test, timer verification, rollback, and a complete file inventory.

---

### Part 08 — Read-only health-check and monitoring report

**Purpose:** Provide a simple, truthful server health report without introducing a monitoring stack.

**Owns:**
- `parts/part-08-healthcheck/`
- `/usr/local/sbin/elsm-healthcheck`;
- `/etc/elsm/healthcheck.conf` template;
- `/var/lib/elsm/health/latest.txt`;
- `/var/log/elsm/healthcheck.log`;
- optional systemd timer for periodic report generation.

**Must deliver:**
- disk usage checks for `/` and mounted `/srv/company`;
- memory and load measurements;
- status of required/optional services;
- failed systemd units;
- SELinux/firewall state;
- backup freshness check if backup part is installed;
- `OK`, `WARN`, `CRITICAL`, and `SKIP` statuses;
- report generation timestamp, actual observed values, and thresholds;
- safe read-only behavior.

**Must not:**
- automatically restart services or delete files;
- fabricate metrics;
- mark an absent optional NFS service as a critical failure;
- edit service configurations;
- depend on Part 07 without gracefully reporting that backup checking is unavailable.

**Acceptance criteria:**
- report contains actual command-derived measurements;
- 80% disk use is WARN and 90% is CRITICAL by default;
- unmounted `/srv/company` is reported as critical;
- absent optional NFS is `SKIP` if NFS is not configured;
- critical results produce a non-zero exit;
- latest report and log permissions are documented.

**Prompt:**

> Implement Part 08 only, based on MASTER_SPEC.md. Create a read-only Bash health checker named `/usr/local/sbin/elsm-healthcheck`, config template `/etc/elsm/healthcheck.conf`, latest report `/var/lib/elsm/health/latest.txt`, and log `/var/log/elsm/healthcheck.log`. Check real disk usage, memory, load, failed systemd units, `sshd`, `httpd`, SELinux mode, firewall status, `/srv/company` mount state, and backup freshness if Part 07 is installed. Use `OK`, `WARN`, `CRITICAL`, and `SKIP`; default disk thresholds are 80% WARN and 90% CRITICAL. Optional NFS should be `SKIP` when not configured. The script must not restart services or delete files. Include config validation, exit codes, sample report, tests for missing dependencies and thresholds, optional scheduling, rollback, and a file inventory. Do not modify backup or service configurations owned by other parts.

---

### Part 09 — Integration, acceptance tests, incident drills, evidence, and release

**Purpose:** Integrate all baseline parts without silently changing their implementation and prove the system works end to end.

**Owns:**
- `parts/part-09-integration/`
- `docs/test-plan.md`;
- `docs/incident-drills.md`;
- `docs/operations-runbook.md`;
- `docs/troubleshooting.md`;
- `docs/evidence/` index and final acceptance report;
- final root README integration (with contributions from other parts).

**Must deliver:**
- dependency-aware deployment order;
- end-to-end acceptance test matrix;
- reboot test;
- permission positive/negative tests;
- web test;
- NFS test or explicit “not run” result;
- backup and restore test;
- health-check test;
- at least five incident drills;
- known limitations and final readiness decision.

**Must not:**
- silently alter other parts' scripts/configuration;
- mark unexecuted tests as passed;
- include sensitive logs, private keys, or backup archives in evidence;
- perform dangerous destructive tests on the OS disk.

**Acceptance criteria:**
- every FR-01 through FR-12 has evidence or an explicit gap;
- tests include commands, expected behavior, actual result, timestamp, and status;
- all changes needed to fix a component are sent to its owner or recorded as a reviewed integration patch;
- final README reproduces the setup from a clean lab.

**Prompt:**

> Implement Part 09 only after reading MASTER_SPEC.md and the deliverables from the other parts. Do not rewrite component code or claim tests passed without running them. Create the integration deployment order, test matrix, incident drills, operations runbook, troubleshooting guide, evidence index, and final acceptance report. Test the entire stack: host identity, storage persistence, user/group permissions including negative cases, Apache, firewall/SELinux, NFS if a client exists, backup creation and restore, health report, and reboot persistence. Include at least five safe incident drills with setup, symptom, diagnosis, remediation, verification, and cleanup. Never run destructive storage tests against the OS disk, and do not commit sensitive logs or archives. For failures, identify the owning part and propose a minimal fix rather than silently changing its files. Mark every test as PASS, FAIL, BLOCKED, or NOT RUN with evidence.

---

### Part 10 — Optional Ansible extension

**Purpose:** Convert stable manual administration procedures into repeatable configuration management.

**Owns:**
- `parts/part-10-ansible-extension/`
- Ansible inventory example, playbooks, roles, and extension README.

**Prerequisite:** Baseline Parts 01–09 pass. This part is not required for RHCSA baseline acceptance.

**Must deliver:**
- inventory with placeholders, no secrets;
- roles for approved users/groups, packages/services, and safe baseline configuration;
- `--check --diff` guidance where applicable;
- idempotency demonstration;
- clear separation between baseline state and optional changes.

**Must not:**
- store passwords in plaintext;
- automatically format disks;
- change firewall/SSH remotely without lockout protection;
- rewrite all baseline scripts into Ansible without a migration plan;
- claim Ansible is a core RHCSA requirement.

**Acceptance criteria:**
- second run reports no unintended changes;
- secrets use Ansible Vault or another appropriate secret-management method;
- destructive storage actions are excluded from unattended playbooks;
- README explains the difference between manual RHCSA practice and configuration management.

**Prompt:**

> Implement the optional Part 10 Ansible extension only after the baseline is stable. Read MASTER_SPEC.md and do not alter the baseline parts. Create an example inventory with placeholders, roles/playbooks for low-risk tasks such as packages, service enablement, groups/users without passwords, and safe configuration checks. Never include plaintext secrets or automated disk formatting. Document inventory variables, vault usage, `--check --diff`, idempotency, and a second-run test. Keep storage/firewall/SSH changes guarded and operator-reviewed. Clearly label this as an advanced extension, not required baseline RHCSA work. Return a file inventory, validation results, and known limitations.

---

## 13. Integration and deployment order

Recommended deployment sequence:

1. **Part 01:** inspect environment, create repository, freeze network plan.
2. Confirm RHEL version, repositories, VM snapshot, and additional data disk identity.
3. **Part 03:** provision and mount `/srv/company`.
4. **Part 02:** create users/groups and department access controls.
5. **Part 05:** deploy Apache portal.
6. **Part 04:** configure NFS if a client VM is available.
7. **Part 07:** configure backup and restore test.
8. **Part 08:** configure health-check and report generation.
9. **Part 06:** review and apply the integrated firewall/SELinux policy with each owner.
10. **Part 09:** run integration tests, reboot tests, incident drills, and evidence capture.
11. **Part 10:** only after baseline acceptance, add Ansible.

Security review (Part 06) may be drafted in parallel, but final hardening must be validated against the actual assembled services. Do not close SSH or apply firewall restrictions before confirming console access and the permitted management source.

---

## 14. Required deliverable format for every part

Each part must return a folder with this minimum shape (adjust only when the part genuinely does not need a file type):

```text
parts/part-XX-name/
├── README.md
├── files/
│   └── (scripts, templates, HTML, or configuration examples)
├── tests/
│   └── (test plan, test script, or manual checklist)
└── evidence/
    └── README.md
```

The README must contain:
1. purpose and scope;
2. dependencies;
3. files included;
4. prerequisites;
5. installation/configuration steps;
6. configuration values and why they exist;
7. security considerations;
8. verification and expected output;
9. failure handling and troubleshooting;
10. rollback/uninstall;
11. known limitations;
12. acceptance checklist;
13. test execution status and date;
14. explicit confirmation of no out-of-scope changes.

---

## 15. Change management and conflict resolution

### Change request template

```markdown
# Change Request: CR-XXXX

- Requested by:
- Date:
- Affected part(s):
- Affected canonical values/paths:
- Current behavior:
- Proposed behavior:
- Reason:
- Security impact:
- Compatibility impact:
- Tests to add/update:
- Rollback:
- Approval:
- Master spec updated before implementation: Yes/No
```

### Conflict resolution order

1. This master specification.
2. Approved change requests merged into this master specification.
3. Part-specific README.
4. Implementation comments.
5. Contributor assumptions.

If a part README or implementation conflicts with the master, the contributor must correct the part deliverable or submit a change request. Do not choose whichever value seems more convenient.

### Integration review checklist

- [ ] Canonical names and paths unchanged.
- [ ] No ownership boundary violated.
- [ ] No unreviewed firewall/SELinux/SSH changes.
- [ ] No secrets or sensitive generated files committed.
- [ ] Scripts use safe Bash practices and have syntax checks.
- [ ] Failure cases are tested.
- [ ] Reboot persistence is tested.
- [ ] Rollback instructions are accurate.
- [ ] Tests are labeled honestly.
- [ ] Documentation and commands match the tested RHEL version.

---

## 16. Troubleshooting decision guide

### Service will not start
1. `systemctl status SERVICE --no-pager`
2. `journalctl -u SERVICE -b --no-pager`
3. Check configuration syntax using the service's validation command.
4. Check port conflicts with `ss -tulpn`.
5. Check ownership and file permissions.
6. Check SELinux denials before changing policy.
7. Apply the owning part's documented fix and repeat the test.

### Client cannot reach service
1. Confirm both VMs are on the intended private network.
2. Check `ip -br address` and `ip route`.
3. Check name resolution or use the known lab IP.
4. Check the service is listening with `ss -tulpn`.
5. Check active firewalld zone and rules.
6. Check SELinux and service logs.
7. Do not open all ports or disable the firewall as a shortcut.

### Company data path is missing
1. `lsblk -f`
2. `findmnt /srv/company`
3. `sudo lvs`
4. `sudo blkid`
5. `sudo findmnt --verify`
6. Review boot logs for mount failures.
7. Do not recreate directories on `/` as a workaround; confirm the data volume is mounted first.

### Backup failed
1. Check source mount.
2. Check destination free space and permissions.
3. Check config values and retention syntax.
4. Check lock state and whether another run is active.
5. Review `/var/log/elsm/backup.log` and the systemd journal.
6. Confirm the archive can be listed and a test file restored.

### SELinux denial suspected
1. Confirm `getenforce` and `sestatus`.
2. Inspect AVC messages with available tools.
3. Confirm expected file labels and port labels.
4. Apply a persistent label or appropriate documented boolean only when justified.
5. Re-test while SELinux remains enforcing.
6. Never use permanent permissive mode as the project solution.

---

## 17. Evidence and portfolio presentation

Capture only evidence that helps a reviewer verify the project. Redact host identifiers or sensitive content if screenshots include them.

Suggested evidence:
- RHEL release and hostname;
- architecture/network diagram;
- `lsblk`, `pvs`, `vgs`, `lvs`, `findmnt`;
- `getent` and `id` for the fictional accounts;
- `getfacl` and successful/denied access tests;
- `systemctl status httpd` and `curl` result;
- `firewall-cmd --list-all` and `getenforce`;
- `exportfs -v` and client mount test if available;
- backup archive listing, manifest/checksum, restore comparison;
- health report;
- one incident drill from detection through recovery;
- reboot persistence checks.

Evidence filenames should be descriptive and ordered, e.g. `01-host-baseline.txt`, `02-storage-layout.txt`, `03-access-tests.txt`, `04-web-service.txt`, `05-security-checks.txt`, `06-backup-restore.txt`, `07-health-report.txt`, `08-reboot-validation.txt`.

Do not include private keys, passwords, real user data, backup archive contents, or unrestricted raw logs.

### Suggested resume bullet (use only after completion)

“Built a RHEL-based Linux server administration lab covering local identity and least-privilege access, LVM/XFS storage, Apache, NFS, firewalld/SELinux, scheduled backup and restore, Bash health checks, incident drills, and documented reboot validation.”

Do not claim production deployment, enterprise scale, high availability, or quantified uptime unless actually demonstrated and measured.

---

## 18. Final definition of done

The baseline is complete only when:
- all required parts are present;
- the master specification and implementation agree;
- the deployment order works on a fresh disposable lab;
- all functional requirements have a test result;
- failures and blocked tests are clearly disclosed;
- the added data disk is safely configured;
- permissions, firewall, and SELinux are validated;
- backup restoration succeeds;
- health checks report real data;
- the server survives reboot;
- incident drills are documented;
- the repository is free of secrets and generated backup artifacts;
- a reviewer can reproduce the lab using only the repository.

**End of master specification.**
