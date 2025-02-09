#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   run_all_tests.sh

# Initialize
# --------------------------------------------------------------------------------------------------

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${CLI_DIR}/core/helpers.sh"
source "${TESTS_DIR}/unit_test_helpers.sh"

# Files to test
# --------------------------------------------------------------------------------------------------

shell_files=$(get_all_shell_files "$CLI_DIR")
files=$(get_all_files "$CLI_DIR")
command_files=$(get_all_command_files "$CLI_DIR")
test_files=$(get_all_test_files "$TESTS_DIR")

# Run tests
# --------------------------------------------------------------------------------------------------

echo "Running tests for:"
echo "- $(count_lines "$shell_files") shell files"
echo "- $(count_lines "$files") files of any type"
echo "- $(count_lines "$command_files") command files"
echo "- $(count_lines "$test_files") test files"

new_section "Shell files should be valid"
"${CUR_DIR}/test_valid_shell_file.sh" "$shell_files"

new_section "All helper files should be valid and have tests"
"${CUR_DIR}/test_helper_files.sh"

new_section "All files should be valid"
"${CUR_DIR}/test_valid_file.sh" "$files"

new_section "All commands should have correct documentation"
"${CUR_DIR}/test_docs.sh"

new_section "Run Python tests"
"${CUR_DIR}/test_python.sh"

new_section "Run ShellCheck, a static analysis tool for shell scripts"
"${CUR_DIR}/test_shell_linter.sh" "$shell_files"

new_section "Run unit tests with shUnit2, a unit test framework for bash scripts"
"${CUR_DIR}/test_shell_unit_tests.sh" "$test_files"
