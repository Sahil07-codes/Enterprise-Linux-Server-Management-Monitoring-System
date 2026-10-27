# Security model

## Trust boundaries

- Management access comes only from the trusted lab host on the private LAN.
- Department access follows Unix groups and ACLs; HR is isolated from other departments.
- Optional NFS is limited to the verified private subnet and uses root squashing.
- Apache serves static information only; no upload endpoint or dynamic application.
- Backups, logs, configuration, and reports are root-controlled and have restrictive permissions where they may contain operational details.
- SELinux remains enforcing.

## Policy checklist

- Confirm active firewalld zone, bound interface, and current rules before changes.
- Allow only SSH/22 from trusted management sources, HTTP/80 from the lab, and NFSv4/2049 only if NFS is configured.
- Validate the intended service listeners with `ss -tulpn`; firewall rules do not prove a service is safe.
- Check `getenforce`, file labels, port labels, and AVC denials. Prefer persistent labels/appropriate booleans to mode changes.
- Validate sudo drop-ins with `visudo -cf`; do not replace `/etc/sudoers`.
- Inspect directory permissions and ACLs with `namei -l` and `getfacl`; run positive and negative access tests.
- Scan Git-tracked files for credentials and generated data before publishing.
- Review NFS exports and ensure `no_root_squash` is absent.
- Keep firewall/SELinux remediation owned by the relevant service owner; this document does not blindly apply changes.

## Lockout and rollback safeguards

Take a VM snapshot, confirm console access, keep an active console session, save the existing firewall state, and test a second SSH session before ending the current one. Revert only the specific rules changed by the approved plan. Do not flush all firewall rules. Restore SELinux enforcing mode after any approved temporary diagnostic and record the reason; acceptance requires enforcing mode.

## Findings record

Record each finding with severity, affected path/service, evidence, owner, minimal remediation, and retest result. Do not report unexecuted checks as passed. See Part 06 checklist.

