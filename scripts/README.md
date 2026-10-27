# Shared scripts

`lib/common.sh` contains small Bash helpers shared by project scripts. It has no side effects on import. Parts should not introduce duplicate timestamp/dependency helpers without checking this file. Validate all scripts with `bash -n`; run ShellCheck when available.

The repository-level automation interface is `bin/elsm` (Python 3 standard library). It coordinates safe tests and read-only verification; it is not a system deployment engine. See `docs/automation-guide.md`.
