#!/usr/bin/env bash

elsm_timestamp() {
    date --iso-8601=seconds
}

elsm_log() {
    local level=$1
    shift
    printf '%s [%s] %s\n' "$(elsm_timestamp)" "$level" "$*"
}

elsm_require_command() {
    local command_name
    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            printf 'Required command not found: %s\n' "$command_name" >&2
            return 3
        fi
    done
}

