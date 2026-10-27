# Storage runbook

This runbook is Part 03's operator-controlled procedure. The data device is environment-specific. The only approved target is a confirmed, additional, disposable virtual disk; there is no automatic formatter.

## Preflight

1. Take a VM snapshot and retain console access.
2. Record `lsblk -f`, `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL`, `pvs`, `vgs`, and `lvs`.
3. Identify the extra disk by VM configuration and device metadata. Check that the entire device is unmounted and not an OS/boot disk.
4. Run `wipefs --no-act DEVICE`. Any signature, partition, PV, or uncertain data means **stop**; do not wipe it.
5. Confirm the exact full device path with a second review.

## Create and mount

Follow the command sequence in [Part 03](../parts/part-03-storage/README.md), replacing the device placeholder only after identification. It creates `vg_elsm/lv_company`, XFS, and `/srv/company`; records a backup of `/etc/fstab`; and mounts by UUID. Stop on any command failure and inspect rather than repeating destructive steps.

Validate `findmnt --verify`, `findmnt /srv/company`, `df -hT /srv/company`, `pvs`, `vgs`, `lvs`, and `blkid`. Reboot and repeat before Part 02 creates data directories.

## Safe expansion

XFS cannot be shrunk. Take a snapshot and backup first. Check `vgs -o vg_name,vg_size,vg_free vg_elsm` and `lvs -o lv_name,lv_size,vg_name vg_elsm`. If the VG has free extents and expansion is approved, choose a reviewed size and run:

```bash
sudo lvextend --size +SIZE /dev/vg_elsm/lv_company
sudo xfs_growfs /srv/company
sudo lvs /dev/vg_elsm/lv_company
df -hT /srv/company
```

Replace `SIZE` with an operator-calculated size that does not exceed free VG capacity. To add a disk, repeat the complete identification/signature-review process, create a PV only on the confirmed empty device, extend `vg_elsm`, and then grow the LV/filesystem. Never use `pvcreate` on a disk with existing content.

## Recovery and rollback

If mount validation fails, use the console; inspect `/etc/fstab`, UUID, LVM activation, and kernel/journal logs. Restore the saved fstab only after reviewing the failure. Do not remove the LV/VG/PV as generic rollback; data destruction requires a separate explicit decision and verified backup.

