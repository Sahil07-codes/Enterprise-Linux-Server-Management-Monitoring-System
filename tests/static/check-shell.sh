#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
files=()
while IFS= read -r -d '' file; do files+=("$file"); done < <(
    find "$root" -type f -print0
)

scripts=()
for file in "${files[@]}"; do
    IFS= read -r first_line <"$file" || true
    first_line=${first_line%$'\r'}
    if [[ ${first_line:-} == '#!/usr/bin/env bash' ]]; then scripts+=("$file"); fi
    unset first_line
done

if ((${#scripts[@]} == 0)); then printf 'No Bash scripts found.\n' >&2; exit 1; fi
for file in "${scripts[@]}"; do
    printf 'Syntax check: %s\n' "${file#"$root"/}"
    bash -n "$file"
done
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${scripts[@]}"
else
    printf 'ShellCheck not installed; syntax checks completed, lint skipped.\n'
fi
if command -v ansible-playbook >/dev/null 2>&1; then
    ansible-playbook \
        -i "$root/parts/part-10-ansible-extension/inventory/hosts.example" \
        "$root/parts/part-10-ansible-extension/playbooks/site.yml" \
        --syntax-check
else
    printf 'ansible-playbook not installed; Ansible syntax check skipped.\n'
fi
printf 'Validated %s shell script(s).\n' "${#scripts[@]}"
