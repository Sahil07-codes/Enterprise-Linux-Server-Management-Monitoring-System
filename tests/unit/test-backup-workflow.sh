#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source_script="$root/parts/part-07-backup/files/elsm-backup"
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT

if ((EUID != 0)); then
    printf 'SKIP | backup workflow test requires root for the production script ownership checks.\n'
    exit 77
fi

fixture="$temporary_directory/fixture"
source_path="$fixture/source/company"
destination_path="$fixture/backups"
log_directory="$fixture/log"
run_directory="$fixture/run/lock"
restore_path="$fixture/restore"
mkdir -p "$source_path" "$destination_path" "$log_directory" "$run_directory" "$restore_path"
printf 'ELSM backup test payload\n' >"$source_path/workflow-test.txt"

config="$fixture/backup.conf"
cat >"$config" <<EOF
BACKUP_SOURCE=$source_path
BACKUP_DEST=$destination_path
RETENTION_DAYS=1
LOG_FILE=$log_directory/backup.log
EOF

test_script="$fixture/elsm-backup"
sed \
    -e "s|/etc/elsm/backup.conf|$config|g" \
    -e "s|/run/lock|$fixture/run/lock|g" \
    -e "s|/srv/company|$source_path|g" \
    -e "s|--directory /srv company|--directory $fixture/source company|g" \
    -e "s|/var/backups/elsm|$destination_path|g" \
    -e "s|/var/log/elsm|$log_directory|g" \
    "$source_script" >"$test_script"
chmod +x "$test_script"

cat >"$fixture/bin-mountpoint" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat >"$fixture/bin-findmnt" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' '/dev/mapper/vg_elsm-lv_company xfs'
MOCK
mock_bin="$fixture/mock-bin"
mkdir -p "$mock_bin"
install -m 0755 "$fixture/bin-mountpoint" "$mock_bin/mountpoint"
install -m 0755 "$fixture/bin-findmnt" "$mock_bin/findmnt"

PATH="$mock_bin:$PATH" bash "$test_script"
archive=$(find "$destination_path" -maxdepth 1 -type f -name 'elsm-*.tar.gz' -print -quit)
if [[ -z $archive ]]; then
    printf 'FAIL | backup did not create an archive\n' >&2
    exit 1
fi
checksum="$archive.sha256"
(cd "$destination_path" && sha256sum --check "$(basename "$checksum")")
tar --extract --gzip --file "$archive" --directory "$restore_path"
cmp "$source_path/workflow-test.txt" "$restore_path/company/workflow-test.txt"
printf 'PASS | archive creation, checksum verification, and restore integrity\n'

old_archive="$destination_path/elsm-expired-test.tar.gz"
printf 'expired fixture\n' >"$old_archive"
printf 'synthetic checksum\n' >"$old_archive.sha256"
touch -d '2 days ago' "$old_archive" "$old_archive.sha256"
sleep 1
PATH="$mock_bin:$PATH" bash "$test_script"
if [[ -e $old_archive || -e $old_archive.sha256 ]]; then
    printf 'FAIL | backup retention left an expired ELSM archive or checksum\n' >&2
    exit 1
fi
printf 'PASS | retention removes only expired ELSM archives and matching checksums\n'

failing_bin="$fixture/failing-bin"
mkdir -p "$failing_bin"
cp "$mock_bin/mountpoint" "$failing_bin/mountpoint"
cp "$mock_bin/findmnt" "$failing_bin/findmnt"
cat >"$failing_bin/tar" <<'MOCK'
#!/usr/bin/env bash
printf 'simulated archive failure\n' >&2
exit 1
MOCK
chmod +x "$failing_bin/tar"
sleep 1
set +e
PATH="$failing_bin:$PATH" bash "$test_script" >"$fixture/failure.out" 2>&1
status=$?
set -e
if ((status == 0)) || ! grep -q 'Backup failed' "$fixture/failure.out"; then
    printf 'FAIL | backup archive failure was not surfaced (exit=%s):\n' "$status" >&2
    cat "$fixture/failure.out" >&2
    exit 1
fi
if find "$destination_path" -maxdepth 1 -type f -name '.elsm-archive.*' | grep -q .; then
    printf 'FAIL | backup failure left a temporary archive behind\n' >&2
    exit 1
fi
printf 'PASS | archive failure returns non-zero and cleans temporary files\n'
