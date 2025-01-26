#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test_valid_shell_file.sh [<shell_files>]

# Initialize
# --------------------------------------------------------------------------------------------------

shell_files=${1:-}

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${TESTS_DIR}/unit_test_helpers.sh"

desired_shebang="#!/usr/bin/env "
desired_set="set -euo pipefail"

# Run tests
# --------------------------------------------------------------------------------------------------

if [ -z "$shell_files" ]; then
  shell_files=$(get_all_shell_files "$CLI_DIR")
fi

invalid_files_shebang=''
invalid_files_set=''
invalid_files_shellcheck=''

while IFS= read -r file; do
    if [[ ! -s "$file" ]]; then
        # File does not exist or is empty
        continue
    fi

    if has_invalid_shebang "$desired_shebang" "$file"; then
        invalid_files_shebang+="\n$file"
    fi

    if has_invalid_set "$desired_set" "$file"; then
        invalid_files_set+="\n$file"
    fi

    if has_shellcheck_all_disabled "$file"; then
        invalid_files_shellcheck+="\n$file"
    fi
done <<<"$shell_files"

new_section_level_2 "All shell files should start with '${desired_shebang}'..."
check_if_error "$invalid_files_shebang"

new_section_level_2 "All shell files should have '${desired_set}' at the top (line 2 or 3)..."
allow_list_regex=".*/core/cli_root/autocomplete.*sh$"
invalid_files_set=$(remove_from_list "$invalid_files_set" "$allow_list_regex")
check_if_error "$invalid_files_set"

new_section_level_2 "There can't be '# shellcheck disable=...' in the beginning of the shell files..."
allow_list_regex=".*/core/helpers/constants.sh$"
invalid_files_shellcheck=$(remove_from_list "$invalid_files_shellcheck" "$allow_list_regex")
check_if_error "$invalid_files_shellcheck"

new_section_level_2 "Shell files should be executable..."
allow_list_regex=".*/tests/helpers.sh$
.*/tests/resources/commands/problematic file.sh$"
invalid_files_executable=$(find_not_executable "$CLI_DIR")
invalid_files_executable=$(remove_from_list "$invalid_files_executable" "$allow_list_regex")
check_if_error "$invalid_files_executable"
