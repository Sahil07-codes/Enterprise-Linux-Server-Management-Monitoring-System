# ADR-0001: Single-server RHEL administration lab

- **Status:** Accepted baseline
- **Decision date:** 2026-10-27

## Context

The project is a learning and portfolio lab requiring RHCSA-oriented administration practice, safe repeatability, and bounded operational scope.

## Decision

Use one RHEL 9 server with local accounts, a separate LVM/XFS data volume, static Apache, optional NFS client integration, firewalld, SELinux enforcing, local scheduled backup/restore, and read-only Bash health reports. Use a private/host-only LAN and manual operator confirmation for disk provisioning.

## Consequences

The design is easy to reproduce in a small VM and exposes the core native administration concepts. It is not highly available, uses local identity, and local backups do not provide off-host disaster recovery. NFS and client validation require a second VM. Optional Ansible is intentionally separate from the baseline.

