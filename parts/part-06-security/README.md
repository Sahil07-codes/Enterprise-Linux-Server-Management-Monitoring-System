# Part 06: Security review

## Scope

This is a cross-component review and read-only audit helper. Discover the active zone, bound interfaces, actual listeners, subnet, and existing rules before proposing changes. Do not blindly flush rules, overwrite service-owned configuration, lock out the only administrator, or set SELinux permissive as a fix.

## Files included

- `files/security-audit`
- `tests/README.md`
- `evidence/README.md`

## Review procedure

1. Confirm console access and snapshot.
2. Run `files/security-audit` with root privileges for complete listener and firewall visibility.
3. Compare results with `docs/security-model.md` and the verified private network plan.
4. Propose a minimal allowlist: SSH from trusted management sources, HTTP from the lab subnet, and NFS only when enabled.
5. Apply owner-reviewed changes using RHEL-native tools, then validate each service while SELinux remains enforcing.

## Firewall rule procedure

These are reviewed examples, not defaults to paste blindly. Set `ZONE` to the discovered zone, `ADMIN_CIDR` to the single trusted administrator address (normally `/32`), and `LAB_CIDR` to the verified private subnet. Keep console access and an active SSH session. Inspect broad existing `ssh`, `http`, or NFS services before changing them.

```bash
sudo firewall-cmd --zone="$ZONE" --add-rich-rule="rule family=ipv4 source address=$ADMIN_CIDR service name=ssh accept"
sudo firewall-cmd --zone="$ZONE" --add-rich-rule="rule family=ipv4 source address=$LAB_CIDR service name=http accept"
```

Test a second SSH session from the approved administrator source and HTTP only from the private LAN. If an existing zone-wide service entry permits broader access, remove only that reviewed entry at runtime after confirming no other workload depends on it. Once runtime behavior is verified, persist the exact approved rich rules and service removals with corresponding `--permanent` commands, then reload and retest. Add NFSv4 TCP/2049 only when Part 04 is enabled. Rollback consists only of reverting these specific rich rules/service entries; never flush the ruleset.

For an enabled NFSv4 server, the reviewed runtime rule is:

```bash
sudo firewall-cmd --zone="$ZONE" --add-rich-rule="rule family=ipv4 source address=$LAB_CIDR port port=2049 protocol=tcp accept"
```

## Verification and rollback

Use `firewall-cmd --get-active-zones`, `firewall-cmd --list-all`, `ss -tulpn`, `getenforce`, `sestatus`, service status, `visudo -cf`, ACL inspection, and recent AVC logs. Keep console access, save prior rules, test a second SSH session, and revert only changed rules if needed.

The audit script is read-only and does not change firewall/SELinux settings. Target review: NOT RUN (2026-10-27).
