# Part 07 tests

Local: `bash -n parts/part-07-backup/files/elsm-backup`; inspect all retention paths before target installation.

Target RHEL: test `--help`, invalid/duplicate config, missing config, and unmounted source behavior. In a disposable mounted lab, create a unique harmless sample file, run a backup, verify `sha256sum -c`, list archive contents, extract the sample only into a fresh temporary directory, compare content, and clean up. Verify timer with `systemctl list-timers --all` and inspect journal/log. Test retention only using old, synthetic ELSM-named test archives in the canonical destination after preserving actual backups. Target tests: NOT RUN.

