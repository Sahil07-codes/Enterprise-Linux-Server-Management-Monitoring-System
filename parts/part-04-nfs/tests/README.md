# Part 04 tests

Server: verify `/srv/company` is a mounted XFS volume; inspect the active export with `sudo exportfs -v`; confirm subnet and options; verify SELinux/firewall policy is handled by Part 06.

Client, if available: mount from `rhel-srv01`, confirm permitted operations, confirm unauthorized operations are denied, and unmount. If no client exists, mark the client test BLOCKED with reason. No NFS test has been executed.

