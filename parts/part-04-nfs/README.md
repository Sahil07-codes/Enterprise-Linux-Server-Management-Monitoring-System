# Part 04: Optional NFS

## Scope and prerequisites

NFS is optional and requires a second lab VM for end-to-end testing. Part 04 owns export/client instructions only; it does not create storage, change ACLs, firewall, or SELinux. Confirm `/srv/company` is mounted from the dedicated XFS filesystem and confirm the actual private subnet before configuring.

## Files included

- `files/elsm.exports.example`
- `tests/README.md`
- `evidence/README.md`

## Server outline

Check enabled repositories, then run `sudo dnf install nfs-utils`. Review `files/elsm.exports.example`, replace the example network with the verified isolated subnet, and deploy to `/etc/exports.d/elsm.exports` only after review. Options use `root_squash`, synchronous writes, and no broad/public scope. Do not use `no_root_squash`. Enable/start `nfs-server` following RHEL documentation for the selected release.

Part 06 must review firewall/SELinux needs before applying them. Prefer NFSv4 over TCP/2049 where supported. Verify with `exportfs -rav`, `exportfs -v`, and service status.

## Client, verification, rollback

On the optional client install `nfs-utils`, create a mount point, and mount the reviewed export:

```bash
sudo dnf install nfs-utils
sudo install -d -o root -g root -m 0755 /mnt/elsm
sudo mount -t nfs4 -o vers=4.2 rhel-srv01:/srv/company /mnt/elsm
findmnt /mnt/elsm
```

Use the version supported by both RHEL systems. Test permitted and denied file operations using harmless test files, then unmount with `sudo umount /mnt/elsm`. Persistent client `fstab` configuration is optional and must be separately reviewed. If no client VM exists, record client integration as BLOCKED/NOT RUN rather than passed.

Rollback: stop client mounts, remove only the ELSM export declaration after backing it up, reload exports, then disable the service only if it is not used elsewhere. Do not remove the data filesystem.

Status: server/client RHEL validation NOT RUN (2026-10-27).
