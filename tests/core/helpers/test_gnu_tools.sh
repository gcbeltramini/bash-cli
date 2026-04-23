#!/usr/bin/env bash
set -euo pipefail

test_use_gnu_tool() {
  local function_return result

  function_return="dummy function"
  # shellcheck disable=SC2317,SC2329
  gfoo() { echo "$function_return"; }

  unset -f foo 2>/dev/null
  use_gnu_tool 'gfoo' # will define the function "foo" from "gfoo"
  result=$(foo)

  assertEquals "$function_return" "$result"
}

test_use_all_gnu_tools() {
  local function_return result

  function_return="dummy function"
  # shellcheck disable=SC2317,SC2329
  g__mycli_test_dummy_function() { echo "$function_return"; }

  unset -f __mycli_test_dummy_function 2>/dev/null
  use_all_gnu_tools # will define '__mycli_test_dummy_function' as 'g__mycli_test_dummy_function' (among many other functions, if they exist)
  result=$(__mycli_test_dummy_function)

  assertEquals "$function_return" "$result"
}

oneTimeSetUp() {
  . core/helpers/gnu_tools.sh
}

. scripts/shunit2
