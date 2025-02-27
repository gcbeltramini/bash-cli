#!/usr/bin/env bash
set -euo pipefail

test_run_python_script() {
  local result expected

  result=$(
    run_python_script \
      "tests/resources/commands/hello/script.py" \
      "--some-int=42" "--some-flag"
  )
  expected="some_int='42', some_flag='True'"
  assertEquals "$expected" "$result"

  result=$(
    run_python_script \
      "tests/python/read_script_metadata.py" \
      "tests/resources/commands/hello/script.py"
  )
  expected="{'requires-python': '>=3.12', 'dependencies': [], 'tool': {'uv': {'exclude-newer': '2001-12-31T23:59:59Z'}}}"
  assertEquals \
    "Test the behavior of the script 'read_script_metadata.py'" \
    "$expected" \
    "$result"
}

oneTimeSetUp() {
  . core/helpers/python.sh
}

. scripts/shunit2
