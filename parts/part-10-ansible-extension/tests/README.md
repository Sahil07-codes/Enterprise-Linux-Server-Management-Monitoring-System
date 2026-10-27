# Part 10 tests

Use a private inventory copy with a confirmed private lab IP. Run `ansible-playbook ... --syntax-check`, then `--check --diff`, apply only after review, and run again to confirm idempotency. Verify user/group state on the target and confirm no storage, firewall, SSH, or SELinux changes were made. Do not store passwords in inventory. Test status: NOT RUN.

