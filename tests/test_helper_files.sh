#!/usr/bin/env bash
set -euo pipefail

# Initialize
# --------------------------------------------------------------------------------------------------

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/..")
TESTS_DIR="${CLI_DIR}/tests"
HELPERS_DIR="${CLI_DIR}/core/helpers"
TESTS_HELPERS_DIR="${TESTS_DIR}/core/test_helpers"

source "${TESTS_DIR}/helpers.sh"

# Run tests
# --------------------------------------------------------------------------------------------------

new_section_level_2 "Every helper file should have a corresponding test file..."
helper_files=$(get_all_helper_files) # excluding "constants.sh"
test_helper_files=$(
    find "$TESTS_HELPERS_DIR" \
        -maxdepth 1 \
        -type f \
        -name '*.sh' |
        sed 's:tests/::g ; s:test_::g'
)
files_without_test=$(comm -23 <(echo "$helper_files" | sort) <(echo "$test_helper_files" | sort))
check_if_error \
    "$files_without_test" \
    "The following files do not have a corresponding test file in '$TESTS_HELPERS_DIR':"

new_section_level_2 "Every function in a helper file should have a corresponding test (test coverage = 100%)..."
helper_functions=$(grep -rE '^[^ #]+() {' "$HELPERS_DIR")
test_helper_functions=$(grep -r '^test_[a-zA-Z0-9_]*' "$TESTS_HELPERS_DIR" | sed 's:tests/::g ; s:test_::g')
functions_without_test=$(
    comm -23 \
        <(echo "$helper_functions" | sort) \
        <(echo "$test_helper_functions" | sort)
)
check_if_error \
    "$functions_without_test" \
    "Functions without test in '$TESTS_HELPERS_DIR':"

new_section_level_2 "Every helper file should only define functions..."
invalid_variable_def_or_fn_call=''
while IFS= read -r file; do
    line=$(get_variable_def_or_fn_call "$file")
    if [[ -n $line ]]; then
        invalid_variable_def_or_fn_call+="\n$file:$line"
    fi
done <<<"$helper_files"
allow_list_regex=".*core/helpers/gnu_tools.sh:use_all_gnu_tools$"
invalid_variable_def_or_fn_call=$(remove_from_list "$invalid_variable_def_or_fn_call" "$allow_list_regex")
check_if_error \
    "$invalid_variable_def_or_fn_call" \
    "Lines defining variables or calling functions:"
