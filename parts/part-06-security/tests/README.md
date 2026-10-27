# Part 06 tests

Local: `bash -n parts/part-06-security/files/security-audit`; run `--help`.

Target: run read-only audit with appropriate privileges. Verify it makes no changes, document active zone/interfaces and listeners, confirm SELinux is enforcing, and compare actual exposure to the intended private subnet. Any remediation must be reviewed, service-owner scoped, and tested with console rollback available. Target audit: NOT RUN.

