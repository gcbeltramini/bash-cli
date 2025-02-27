#!/usr/bin/env bash
set -euo pipefail

test_to_uppercase() {
  local result

  result=$(to_uppercase 'Foo BaR')
  assertEquals 'FOO BAR' "$result"

  result=$(to_uppercase '')
  assertEquals '' "$result"

  result=$(to_uppercase 'AbC 12DEf')
  assertEquals 'ABC 12DEF' "$result"
}

test_to_lowercase() {
  local result

  result=$(to_lowercase 'Foo BaR')
  assertEquals 'foo bar' "$result"

  result=$(to_lowercase '')
  assertEquals '' "$result"

  result=$(to_lowercase 'AbC 12DEf')
  assertEquals 'abc 12def' "$result"
}

test_repeat_char() {
  local result

  result=$(repeat_char 'x' 4)
  assertEquals 'xxxx' "$result"

  result=$(repeat_char 'xy' 3)
  assertEquals 'xyxyxy' "$result"

  result=$(repeat_char 'a' 1)
  assertEquals 'a' "$result"

  result=$(repeat_char 'a' 0)
  assertEquals '' "$result"
}

test_surround_text() {
  local result
  result=$(surround_text " Hello " 20 "-")
  assertEquals '------ Hello -------' "$result"

  result=$(surround_text " Hello " 2 "=")
  assertEquals '= Hello =' "$result"
}

test_count_lines() {
  local result text

  text="foo
    bar"
  result=$(count_lines "$text")
  assertEquals 2 "$result"

  text="
    foo
    bar
    "
  result=$(count_lines "$text")
  assertEquals 2 "$result"

  text="

    "
  result=$(count_lines "$text")
  assertEquals 0 "$result"
}

test_remove_from_list() {
  local result expected
  local -r list1="foo\nbar baz\n12"
  local -r list2=$(echo -e "$list1")

  result=$(remove_from_list "$list1" "foo")
  expected=$(echo -e "bar baz\n12")
  assertEquals "$expected" "$result"

  result=$(remove_from_list "$list2" "foo")
  assertEquals "$expected" "$result"

  result=$(remove_from_list "$list1" "^b\n^[f]oo")
  expected=$(echo -e "12")
  assertEquals "$expected" "$result"

  result=$(remove_from_list "$list2" "^b\n^[f]oo")
  assertEquals "$expected" "$result"

  result=$(remove_from_list "$list1" "  ")
  expected=$list2
  assertEquals "$expected" "$result"

  result=$(remove_from_list "$list2" "")
  assertEquals "$expected" "$result"
}

oneTimeSetUp() {
  . core/helpers/string.sh
}

. scripts/shunit2
