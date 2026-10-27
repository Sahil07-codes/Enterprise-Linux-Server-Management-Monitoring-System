# Target VM acceptance checklist

- [ ] Record RHEL version, kernel, hostname, network, repositories, SELinux, and failed units.
- [ ] Confirm VM snapshot and console access.
- [ ] Identify extra disk and verify no unreviewed content; operator confirmation recorded.
- [ ] Create and verify `vg_elsm/lv_company`, XFS, UUID mount `/srv/company`.
- [ ] Reboot and confirm mount persistence.
- [ ] Verify canonical users/groups, sudoers syntax, directory ACLs, positive and negative access.
- [ ] Verify Apache locally and from allowed private client.
- [ ] Verify firewall active zone and explicit service scope; SELinux remains enforcing.
- [ ] Verify NFS if client exists; otherwise mark blocked/not run.
- [ ] Run scheduled backup, inspect manifest/checksum, restore sample file to temporary directory.
- [ ] Verify health measurements, statuses, exit code, report and log permissions.
- [ ] Perform at least five safe incident drills and cleanup.
- [ ] Reboot and validate services, timer, firewall, SELinux, and mounts.
- [ ] Review Git tree for secrets, archives, VM artifacts, and unfiltered logs.

For each item record date, exact command, expected and actual output, status, and sanitized evidence path.

