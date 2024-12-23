#!/usr/bin/env bash
set -euo pipefail

# Initialize
# --------------------------------------------------------------------------------------------------

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${CLI_DIR}/core/helpers.sh"
source "${TESTS_DIR}/helpers.sh"

# Files to test
# --------------------------------------------------------------------------------------------------

shell_files=$(get_all_shell_files "$CLI_DIR")
files=$(get_all_files "$CLI_DIR")
test_helper_files=$(get_all_test_helper_files "$TESTS_DIR")

shell_files_array=()
while IFS= read -r file; do
    shell_files_array+=("$file")
done <<<"$shell_files"

# Run tests
# --------------------------------------------------------------------------------------------------

echo "Running tests for:"
echo "- $(count_lines "$shell_files") shell files"
echo "- $(count_lines "$files") files of any type"
echo "- $(count_lines "$test_helper_files") test helpers"

new_section "Shell files should be valid"
"${TESTS_DIR}/test_valid_shell_file.sh" "$shell_files"
echo_done

new_section "All helper files should be valid and have tests"
"${TESTS_DIR}"/test_helper_files.sh
echo_done

new_section "All commands should have valid names"
new_section_level_2 "No folder 'update' or 'version' in the 'commands' folder, and no command with spaces"
invalid_cmds=$(check_forbidden_cmd_name "$CLI_DIR")
check_if_error "$invalid_cmds" "Invalid folders and files:"
echo_done

new_section "All files should have exactly one empty line at the end"
invalid_files_lines_at_the_end=''
while IFS= read -r file; do
    if [[ ! -s "$file" ]]; then
        # File does not exist or is empty
        continue
    fi

    if has_exactly_one_line_at_the_end "$file"; then
        invalid_files_lines_at_the_end+="\n$file"
    fi
done <<<"$files"
check_if_error "$invalid_files_lines_at_the_end"
echo_done

new_section "Run ShellCheck, a static analysis tool for shell scripts"
shellcheck "${shell_files_array[@]}" --shell=bash
echo_done

new_section "Run unit tests with shUnit2, a unit test framework for bash scripts"
while IFS= read -r test_file; do
    echo
    get_test_running_message "$test_file" "$CLI_DIR"
    "$test_file"
done <<<"$test_helper_files"
echo_done
