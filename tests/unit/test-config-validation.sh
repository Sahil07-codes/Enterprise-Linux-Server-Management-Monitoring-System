#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT

expect_config_error() {
    local script=$1 config=$2 expected=$3 output status
    set +e
    output=$(bash "$script" --config "$config" 2>&1)
    status=$?
    set -e
    if ((status != 2)) || [[ $output != *"$expected"* ]]; then
        printf 'Expected config error containing "%s" (exit 2); got exit %s:\n%s\n' "$expected" "$status" "$output" >&2
        exit 1
    fi
    printf 'PASS | rejected invalid configuration: %s\n' "$expected"
}

backup_config="$temporary_directory/backup.conf"
printf '%s\n' \
    'BACKUP_SOURCE=/srv/company' \
    'BACKUP_DEST=/var/backups/elsm' \
    'RETENTION_DAYS=0' \
    'LOG_FILE=/var/log/elsm/backup.log' >"$backup_config"
expect_config_error "$root/parts/part-07-backup/files/elsm-backup" "$backup_config" 'RETENTION_DAYS must be'

health_config="$temporary_directory/healthcheck.conf"
printf '%s\n' \
    'DISK_WARN_PERCENT=90' \
    'DISK_CRITICAL_PERCENT=80' >"$health_config"
expect_config_error "$root/parts/part-08-healthcheck/files/elsm-healthcheck" "$health_config" 'Disk warn must be below critical'

