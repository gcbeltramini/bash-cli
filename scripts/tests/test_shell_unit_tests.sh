#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test_shell_unit_tests.sh [<test_files>]

# Initialize
# --------------------------------------------------------------------------------------------------

test_files=${1:-}

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${TESTS_DIR}/unit_test_helpers.sh"

# Run tests
# --------------------------------------------------------------------------------------------------

if [ -z "$test_files" ]; then
  test_files=$(get_all_test_files "$TESTS_DIR")
fi

# For debugging:
# echo >&2 -e "[DEBUG] Test files:\n'$test_files'"

pushd "$CLI_DIR" >/dev/null
while IFS= read -r test_file; do
  echo
  get_test_running_message "$test_file" "$CLI_DIR"
  "$test_file"
done <<<"$test_files"
popd >/dev/null

echo_done
