#!/usr/bin/env bash
set -euo pipefail

test_get_color_code() {
  local result

  result=$(get_color_code 'no_color')
  assertEquals '\x1b[0m' "$result"

  result=$(get_color_code 'red')
  assertEquals '\x1b[31m' "$result"

  result=$(get_color_code 'RED')
  assertEquals '\x1b[31m' "$result"

  result=$(get_color_code 'green')
  assertEquals '\x1b[32m' "$result"

  result=$(get_color_code 'blue')
  assertEquals '\x1b[34m' "$result"
}

test_echo_color() {
  local result expected

  result=$(echo_color "red" "Some error message")
  expected=$(echo -e '\x1b[31mSome error message\x1b[0m')
  assertEquals "$expected" "$result"

  result=$(echo_color "cyan" "No line skip" -n)
  expected=$(echo -e '\x1b[36mNo line skip\x1b[0m') # it seems that '-n' is not necessary for the test to pass
  assertEquals "$expected" "$result"
}

test_echo_error() {
  local result expected

  result=$(echo_error "an error message" 2>&1)
  expected=$(echo -e '\x1b[31m[ERROR] an error message\x1b[0m')
  assertEquals "$expected" "$result"
}

test_echo_warn() {
  local result expected

  result=$(echo_warn "a warning message" 2>&1)
  expected=$(echo -e '\x1b[33m[WARNING] a warning message\x1b[0m')
  assertEquals "$expected" "$result"
}

test_echo_info() {
  local result expected

  result=$(echo_info "My info message" 2>&1)
  expected=$(echo -e '\x1b[0m[INFO] My info message\x1b[0m')
  assertEquals "$expected" "$result"
}

test_echo_debug() {
  local result expected

  result=$(echo_debug "This is a debug message" 2>&1)
  expected=$(echo -e '\x1b[90m[DEBUG] This is a debug message\x1b[0m')
  assertEquals "$expected" "$result"
}

test_echo_done() {
  local result expected

  result=$(echo_done 2>&1)
  expected=$(echo -e '\x1b[32mDone!\x1b[0m')
  assertEquals "$expected" "$result"
}

test_echo_success() {
  local result expected

  result=$(echo_success 2>&1)
  expected=$(echo -e '\x1b[32mSuccess!\x1b[0m')
  assertEquals "$expected" "$result"
}

test_new_section() {
  local result expected

  result=$(new_section "Some Title")
  expected='
====================================================================================================
Some Title
===================================================================================================='
  assertEquals "$expected" "$result"
}

test_new_section_with_color() {
  local result expected

  result=$(new_section_with_color "green" "My new Section")
  expected=$(echo -e '\x1b[32m
====================================================================================================
My new Section
====================================================================================================\x1b[0m')
  assertEquals "$expected" "$result"
}

test_debug_var_in_file() {
  local result expected

  # shellcheck disable=SC2034
  local -r ab=42
  # shellcheck disable=SC2034
  local -r my_array=(11 22 33)

  # Associative arrays are ignored
  declare -A my_associative_array
  my_associative_array=(["k1"]="v1" ["k2"]="v2")
  export my_associative_array

  result=$(debug_var_in_file "/my/parent/dir/my-filename" "/my/parent/dir" 123 'ab' 'cd' 'my_array' 'my_associative_array' 2>&1)
  expected=$(echo -e "\x1b[33m>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Debug variables (my-filename:123) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\x1b[0m
ab='42'
cd=<not set>
my_array='11' '22' '33'
my_associative_array=<not set>
\x1b[33m<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\x1b[0m")
  assertEquals "$expected" "$result"
}

test_debug_var() {
  # Tested in `test_debug_var_in_file``.
  true
}

oneTimeSetUp() {
  . core/helpers/constants.sh
  . core/helpers/echo.sh
  . core/helpers/string.sh
  . core/helpers/variables.sh
}

. scripts/shunit2
