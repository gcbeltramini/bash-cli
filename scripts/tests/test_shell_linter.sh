#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test_shell_linter.sh [<shell_files>]

# Initialize
# --------------------------------------------------------------------------------------------------

shell_files=${1:-}

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${TESTS_DIR}/unit_test_helpers.sh"

# Run tests
# --------------------------------------------------------------------------------------------------

if [ -z "$shell_files" ]; then
  shell_files=$(get_all_shell_files "$CLI_DIR")
fi

# For debugging:
# echo >&2 -e "[DEBUG] Shell files:\n'$shell_files'"

shell_files_array=()
while IFS= read -r file; do
  shell_files_array+=("$file")
done <<<"$shell_files"

new_section_level_2 "Every shell file should pass the shell linter (ShellCheck)..."
shellcheck "${shell_files_array[@]}" --shell=bash

echo
echo_done
