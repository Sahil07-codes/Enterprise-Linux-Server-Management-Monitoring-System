#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
script="$root/parts/part-03-storage/files/validate-storage"
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT
mock_bin="$temporary_directory/bin"
mkdir -p "$mock_bin"

for command_name in date lsblk pvs vgs lvs blkid df; do
    cat >"$mock_bin/$command_name" <<'MOCK'
#!/usr/bin/env bash
printf 'fixture output\n'
MOCK
    chmod +x "$mock_bin/$command_name"
done

cat >"$mock_bin/findmnt" <<'MOCK'
#!/usr/bin/env bash
case ${1:-} in
    --mountpoint)
        [[ ${ELSM_STORAGE_MOUNTED:-yes} == yes ]]
        ;;
    --noheadings)
        printf '%s %s\n' "${ELSM_STORAGE_SOURCE:-/dev/mapper/vg_elsm-lv_company}" \
            "${ELSM_STORAGE_TYPE:-xfs}"
        ;;
    --verify)
        exit 0
        ;;
    *)
        exit 2
        ;;
esac
MOCK
chmod +x "$mock_bin/findmnt"

output=$(PATH="$mock_bin:$PATH" bash "$script" 2>&1) || {
    printf 'FAIL | storage validator rejected the expected XFS fixture:\n%s\n' "$output" >&2
    exit 1
}
[[ $output == *'filesystem: xfs'* ]] || {
    printf 'FAIL | storage validator omitted expected mount details:\n%s\n' "$output" >&2
    exit 1
}
printf 'PASS | storage validator accepts expected LVM/XFS mount\n'

set +e
output=$(ELSM_STORAGE_TYPE=ext4 PATH="$mock_bin:$PATH" bash "$script" 2>&1)
status=$?
set -e
if ((status == 0)) || [[ $output != *'Expected XFS'* ]]; then
    printf 'FAIL | storage validator accepted a non-XFS filesystem (exit=%s):\n%s\n' \
        "$status" "$output" >&2
    exit 1
fi
printf 'PASS | storage validator rejects an unexpected filesystem\n'

set +e
output=$(ELSM_STORAGE_MOUNTED=no PATH="$mock_bin:$PATH" bash "$script" 2>&1)
status=$?
set -e
if ((status == 0)) || [[ $output != *'/srv/company is not mounted.'* ]]; then
    printf 'FAIL | storage validator accepted an unmounted company path (exit=%s):\n%s\n' \
        "$status" "$output" >&2
    exit 1
fi
printf 'PASS | storage validator rejects an unmounted company path\n'
