#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test_valid_file.sh [<files>]

# Initialize
# --------------------------------------------------------------------------------------------------

files=${1:-}

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${TESTS_DIR}/unit_test_helpers.sh"

# Run tests
# --------------------------------------------------------------------------------------------------

if [ -z "$files" ]; then
  files=$(get_all_files "$CLI_DIR")
fi

# For debugging:
# echo >&2 -e "[DEBUG] Files:\n'$files'"

new_section_level_2 "No folder 'update' or 'version' in the 'commands' folder, and no command with spaces"
invalid_cmds=$(find_forbidden_cmd_names "$CLI_DIR")
check_if_error "$invalid_cmds" "Invalid folders and files:"

new_section_level_2 "All files should have exactly one empty line at the end"
invalid_files_lines_at_the_end=''
while IFS= read -r file; do
  if [[ ! -s "$file" ]]; then
    # File does not exist or is empty
    continue
  fi

  if ! has_exactly_one_line_at_the_end "$file"; then
    invalid_files_lines_at_the_end+="\n$file"
  fi
done <<<"$files"
allow_list_regex=".*/tests/resources/commands/problematic file.sh$
.*/tests/resources/commands/no_newline_at_the_end.txt$"
invalid_files_lines_at_the_end=$(remove_from_list "$invalid_files_lines_at_the_end" "$allow_list_regex")
check_if_error "$invalid_files_lines_at_the_end"

echo
echo_done
