# Part 09 tests

Local static checks: `bash -n tests/integration/elsm-smoke-check`, then run `bash tests/static/check-shell.sh`.

On RHEL, run the smoke check for read-only state, then execute the target acceptance checklist. It reports `FAIL` when required baseline conditions do not hold and `SKIP` for NFS unless configured. It does not create test data or change services. Follow the component-specific tests for access and restore behavior. Target execution: NOT RUN.

