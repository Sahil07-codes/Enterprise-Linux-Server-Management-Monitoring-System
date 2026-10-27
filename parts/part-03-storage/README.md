# Part 03: LVM and XFS storage

## Scope and safety

This part provides an operator-run procedure and read-only validator for the added disposable virtual disk. It owns `vg_elsm`, `lv_company`, XFS, and `/srv/company`. **No script in this part formats or modifies a disk.** The exact device is never assumed.

## Files included

- `files/validate-storage`
- `tests/README.md`
- `evidence/README.md`
- [`docs/storage-runbook.md`](../../docs/storage-runbook.md)

## Prerequisites

Check package/repository availability and install `lvm2` and `xfsprogs` if required (`sudo dnf install lvm2 xfsprogs`). Take a VM snapshot. Keep console access. Run `lsblk -f`, `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL`, `pvs`, `vgs`, and `lvs`. Confirm the candidate disk is the added disposable disk, is not mounted, and has no signatures/data. If anything is ambiguous or already present, stop.

## Operator-confirmed deployment outline

The following is intentionally manual and destructive if the wrong device is selected. Replace `CONFIRMED_DEVICE` only after review; never paste the placeholder literally.

```bash
sudo lsblk -f
sudo lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL
sudo wipefs --no-act /dev/CONFIRMED_DEVICE
```

Set `DATA_DISK` below to the fully reviewed device path. Any existing signature, partition, mount, PV, or uncertain content is a stop condition; do not run the creation commands.

```bash
set -Eeuo pipefail
DATA_DISK=/dev/REPLACE_WITH_CONFIRMED_DEVICE
lsblk -f "$DATA_DISK"
sudo wipefs --no-act "$DATA_DISK"
read -r -p "Type the exact device path to confirm this disposable disk: " CONFIRM
[[ $CONFIRM == "$DATA_DISK" ]] || { printf 'Confirmation did not match; stopping.\n' >&2; exit 1; }
if sudo vgs vg_elsm >/dev/null 2>&1 || sudo lvs /dev/vg_elsm/lv_company >/dev/null 2>&1; then
  printf 'Canonical ELSM volume names already exist; inspect state and stop.\n' >&2
  exit 1
fi
if grep -qE '^[[:space:]]*[^#].*[[:space:]]/srv/company[[:space:]]' /etc/fstab; then
  printf '/srv/company already has an fstab entry; inspect it and stop.\n' >&2
  exit 1
else
  grep_status=$?
  if ((grep_status != 1)); then printf 'Could not inspect /etc/fstab; stopping.\n' >&2; exit 1; fi
fi
[[ -f /etc/fstab && ! -L /etc/fstab ]] || { printf '/etc/fstab is not a regular file; stopping.\n' >&2; exit 1; }
sudo cp -a /etc/fstab "/etc/fstab.elsm-backup.$(date +%Y%m%d%H%M%S)" || { printf 'Could not back up fstab; stopping.\n' >&2; exit 1; }

sudo pvcreate "$DATA_DISK" || { printf 'pvcreate failed; stopping.\n' >&2; exit 1; }
sudo vgcreate vg_elsm "$DATA_DISK" || { printf 'vgcreate failed; inspect state before continuing.\n' >&2; exit 1; }
sudo lvcreate --name lv_company --extents 100%FREE vg_elsm || { printf 'lvcreate failed; inspect state before continuing.\n' >&2; exit 1; }
sudo mkfs.xfs /dev/vg_elsm/lv_company || { printf 'mkfs.xfs failed; inspect state before continuing.\n' >&2; exit 1; }
sudo install -d -o root -g root -m 0755 /srv/company || { printf 'Could not prepare mount point; stopping.\n' >&2; exit 1; }
UUID=$(sudo blkid --match-tag UUID --output value /dev/vg_elsm/lv_company)
test -n "$UUID" || { printf 'Filesystem UUID unavailable; stopping.\n' >&2; exit 1; }
printf 'UUID=%s /srv/company xfs defaults 0 0\n' "$UUID" | sudo tee -a /etc/fstab >/dev/null || { printf 'Could not update fstab; stopping.\n' >&2; exit 1; }
sudo findmnt --verify || { printf 'fstab validation failed; do not mount or reboot.\n' >&2; exit 1; }
sudo mount /srv/company || { printf 'Mount failed; inspect fstab and LVM state.\n' >&2; exit 1; }
```

Do not continue if `findmnt --verify` or mount fails; restore the saved fstab only after reviewing the exact failure. Verify `findmnt`, `df -hT`, `pvs`, `vgs`, and `lvs`. Reboot and repeat the checks before Part 02 creates directories.

## Validation and recovery

Run `files/validate-storage` after the filesystem has been created. Reboot validation is required. For recovery, use console and the VM snapshot; inspect LVM metadata and `/etc/fstab` before making changes. Never destroy the LV or PV as generic rollback. Expansion requires free VG space, a snapshot/backup, and a reviewed XFS grow procedure.

Target-RHEL and reboot acceptance: NOT RUN (2026-10-27).
