#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT
config="$temporary_directory/healthcheck.conf"
printf '%s\r\n' \
    'DISK_WARN_PERCENT=80' \
    'DISK_CRITICAL_PERCENT=90' \
    'MEMORY_WARN_AVAILABLE_PERCENT=15' \
    'MEMORY_CRITICAL_AVAILABLE_PERCENT=5' \
    'LOAD_WARN_1M=2.00' \
    'LOAD_CRITICAL_1M=4.00' \
    'BACKUP_MAX_AGE_HOURS=36' \
    'NFS_ENABLED=false' >"$config"
bash "$root/parts/part-08-healthcheck/files/elsm-healthcheck" \
    --config "$config" \
    --self-test-thresholds
