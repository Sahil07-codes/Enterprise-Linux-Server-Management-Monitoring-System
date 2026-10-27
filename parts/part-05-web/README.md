# Part 05: Apache portal

## Scope and deployment

This part serves static project information only. Review `files/index.html`, install `httpd` after checking package availability, copy the HTML to `/var/www/html/index.html`, then enable/start `httpd` using `systemctl`. Do not modify firewalld or SELinux mode; Part 06 reviews HTTP exposure and SELinux labeling.

## Files included

- `files/index.html`
- `tests/README.md`
- `evidence/README.md`

```bash
sudo dnf install httpd
sudo install -o root -g root -m 0644 parts/part-05-web/files/index.html /var/www/html/index.html
sudo systemctl enable --now httpd
```

Part 06 must permit HTTP only on the verified private lab network. If SELinux context is incorrect, inspect it with `ls -Z` and restore the standard web-content context using the RHEL-supported labeling tools; do not disable SELinux.

## Verification and troubleshooting

Run `curl --fail http://localhost/`, `systemctl is-enabled httpd`, `systemctl status httpd`, and inspect `journalctl -u httpd`. Test remote access only from the isolated lab subnet. Confirm the file has standard Apache-readable ownership/mode and correct SELinux context with `ls -Z`.

Rollback: save the existing index first; restore it or remove only the project page, then stop/disable Apache only if it is not used by another service. Do not disable SELinux to troubleshoot.

Acceptance: expected page returned locally and from allowed private client; enabled service survives reboot. Target-RHEL tests: NOT RUN (2026-10-27).
