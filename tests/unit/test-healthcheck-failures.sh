#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source_script="$root/parts/part-08-healthcheck/files/elsm-healthcheck"
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT

if ((EUID != 0)); then
    printf 'SKIP | health failure test requires root because the production report writer enforces it.\n'
    exit 77
fi

fixture="$temporary_directory/fixture"
mock_bin="$fixture/mock-bin"
mkdir -p "$mock_bin" "$fixture/company" "$fixture/state" "$fixture/log"
test_script="$fixture/elsm-healthcheck"
sed \
    -e "s|/var/lib/elsm|$fixture/state|g" \
    -e "s|/var/log/elsm|$fixture/log|g" \
    -e "s|/srv/company|$fixture/company|g" \
    "$source_script" >"$test_script"
chmod +x "$test_script"

cat >"$mock_bin/mountpoint" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat >"$mock_bin/df" <<'MOCK'
#!/usr/bin/env bash
printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/mock 100 1 99 1%% /\n'
MOCK
cat >"$mock_bin/systemctl" <<'MOCK'
#!/usr/bin/env bash
if [[ ${1:-} == --failed ]]; then exit 0; fi
if [[ ${1:-} == is-active && ${2:-} == --quiet ]]; then
    [[ ${3:-} != httpd && ${3:-} != nfs-server ]]
    exit
fi
if [[ ${1:-} == is-active ]]; then
    printf '%s\n' inactive
    exit 3
fi
exit 2
MOCK
cat >"$mock_bin/firewall-cmd" <<'MOCK'
#!/usr/bin/env bash
case ${1:-} in
    --state) printf 'running\n' ;;
    --get-active-zones) printf 'public\n  interfaces: eth0\n' ;;
    *) exit 2 ;;
esac
MOCK
cat >"$mock_bin/getenforce" <<'MOCK'
#!/usr/bin/env bash
printf 'Enforcing\n'
MOCK
chmod +x "$mock_bin"/*

set +e
output=$(PATH="$mock_bin:$PATH" bash "$test_script" --config /dev/null 2>&1)
status=$?
set -e
if ((status != 1)); then
    printf 'FAIL | critical health conditions should return exit 1; received %s:\n%s\n' "$status" "$output" >&2
    exit 1
fi
report="$fixture/state/health/latest.txt"
if [[ ! -f $report ]] || ! grep -q "Filesystem $fixture/company | not mounted" "$report" \
    || ! grep -q 'Service httpd | state=inactive' "$report" \
    || ! grep -q 'Overall: CRITICAL' "$report"; then
    printf 'FAIL | health report omitted expected critical findings:\n%s\n' "$output" >&2
    if [[ -f $report ]]; then cat "$report" >&2; fi
    exit 1
fi
printf 'PASS | unmounted storage and inactive service are reported as critical with non-zero status\n'
