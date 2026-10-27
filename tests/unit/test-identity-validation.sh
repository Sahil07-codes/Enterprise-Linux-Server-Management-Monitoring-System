#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
script="$root/parts/part-02-identity-access/files/provision-identities"
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT

if ((EUID != 0)); then
    printf 'SKIP | identity dry-run validation requires root to exercise the production preflight.\n'
    exit 77
fi

mock_bin="$temporary_directory/bin"
company_root="$temporary_directory/company"
mkdir -p "$mock_bin" "$company_root"
test_script="$temporary_directory/provision-identities"
sed \
    -e "s|/srv/company|$company_root|g" \
    -e "s|/etc/sudoers.d/elsm-labadmin|$temporary_directory/elsm-labadmin|g" \
    "$script" >"$test_script"
chmod +x "$test_script"

cat >"$mock_bin/mountpoint" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat >"$mock_bin/readlink" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' 'COMPANY_ROOT_FIXTURE'
MOCK
cat >"$mock_bin/getent" <<'MOCK'
#!/usr/bin/env bash
if [[ ${ELSM_IDENTITY_CASE:-valid} == mismatch && $1 == passwd && $2 == labadmin ]]; then
    exit 0
fi
exit 2
MOCK
cat >"$mock_bin/id" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' unrelated
MOCK
for command_name in groupadd useradd usermod install visudo setfacl chmod mktemp; do
    cat >"$mock_bin/$command_name" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
done
chmod +x "$mock_bin"/*
sed -i "s|COMPANY_ROOT_FIXTURE|$company_root|" "$mock_bin/readlink"

set +e
output=$(PATH="$mock_bin:$PATH" bash "$test_script" --dry-run 2>&1)
status=$?
set -e
if ((status != 0)) || [[ $output != *'Dry run; no system changes will be made.'* ]]; then
    printf 'FAIL | identity valid dry-run did not pass preflight:\n%s\n' "$output" >&2
    exit 1
fi
printf 'PASS | identity dry-run validates clean prerequisites without changes\n'

set +e
output=$(ELSM_IDENTITY_CASE=mismatch PATH="$mock_bin:$PATH" bash "$test_script" --dry-run 2>&1)
status=$?
set -e
if ((status == 0)) || [[ $output != *'different primary group'* ]]; then
    printf 'FAIL | identity preflight accepted a conflicting existing primary group (exit=%s):\n%s\n' \
        "$status" "$output" >&2
    exit 1
fi
printf 'PASS | identity preflight rejects a conflicting existing primary group\n'
