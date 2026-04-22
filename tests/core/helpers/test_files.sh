#!/usr/bin/env bash
set -euo pipefail

test_backup_if_exists() {
  local -r file_that_doesnt_exist='i-dont-exist.txt'
  backup_if_exists "$file_that_doesnt_exist"
  assertFalse "[ -f $file_that_doesnt_exist ]"

  assertTrue "[ -f $mock_file ]"
  assertFalse "[ -f ${mock_file}.20*.bkp ]"
  backup_if_exists "$mock_file" >/dev/null 2>&1
  assertTrue "[ -f $mock_file ]"
  assertTrue "[ -f ${mock_file}.20*.bkp ]"
}

test_check_if_file_exists() {
  # shellcheck disable=SC2016
  assertTrue 'check_if_file_exists "$mock_file" &>/dev/null'
  assertFalse 'check_if_file_exists "i-do-not-exist.txt" &>/dev/null'
}

test_file_to_base64() {
  local tmp_file result expected
  tmp_file="$(mktemp)"
  printf 'hello' >"$tmp_file"

  result="$(file_to_base64 "$tmp_file")"
  expected="aGVsbG8="

  rm -f "$tmp_file"
  assertEquals "$expected" "$result"
}

test_find_relevant_files() {
  local result expected

  result=$(find_relevant_files "$RESOURCES_DIR/hello" | LC_COLLATE=C sort)
  expected=$(
    cat <<-EOF
	$RESOURCES_DIR/hello/README.md
	$RESOURCES_DIR/hello/hello-world.sh
	$RESOURCES_DIR/hello/script.py
EOF
  )
  assertEquals "$expected" "$result"

  result=$(find_relevant_files "$RESOURCES_DIR/hello" -name '*.sh' | sort)
  expected=$(
    cat <<-EOF
	$RESOURCES_DIR/hello/hello-world.sh
EOF
  )
  assertEquals "$expected" "$result"
}

test_files_not_ending_with_newline() {
  local result expected

  result=$(files_not_ending_with_newline "$(find_relevant_files "$RESOURCES_DIR")" | sort)
  expected="$RESOURCES_DIR/no_newline_at_the_end.txt"
  assertEquals "$expected" "$result"

  files=$(
    cat <<-EOF
	$RESOURCES_DIR/no_newline_at_the_end.txt
	$RESOURCES_DIR/problematic file.sh
EOF
  )
  result=$(files_not_ending_with_newline "$files")
  expected="$RESOURCES_DIR/no_newline_at_the_end.txt"
  assertEquals "$expected" "$result"
}

test_has_exactly_one_line_at_the_end() {
  local result
  # shellcheck disable=SC2016
  assertTrue 'has_exactly_one_line_at_the_end "$RESOURCES_DIR/hello/hello-world.sh"'

  # shellcheck disable=SC2016
  assertFalse 'has_exactly_one_line_at_the_end "$RESOURCES_DIR/problematic file.sh"'

  has_exactly_one_line_at_the_end "$RESOURCES_DIR/problematic file.sh"
  result=$?
  assertEquals 2 "$result"

  # shellcheck disable=SC2016
  assertFalse 'has_exactly_one_line_at_the_end "$RESOURCES_DIR/no_newline_at_the_end.txt"'

  has_exactly_one_line_at_the_end "$RESOURCES_DIR/no_newline_at_the_end.txt"
  result=$?
  assertEquals 1 "$result"
}

test_yaml2json() {
  # If we want to avoid the dependence on 'PyYAML', uncomment the lines below.
  # if ! python -c 'import yaml' &>/dev/null; then
  #   echo >&2 "Skipping 'test_yaml2json': PyYAML (python module 'yaml') is not installed."
  #   return 0
  # fi

  local result expected yaml_content

  yaml_content=$(
    cat <<-EOF
name: foo
value: 42
nested:
  key: bar
EOF
  )
  result=$(yaml2json <(echo "$yaml_content"))
  expected=$(
    cat <<-EOF
{
  "name": "foo",
  "value": 42,
  "nested": {
    "key": "bar"
  }
}
EOF
  )
  assertEquals "$expected" "$result"
}

test_find_dirs_with_only_hidden_files() {
  local result expected

  result=$(find_dirs_with_only_hidden_files "$RESOURCES_DIR" | sort)
  expected=$(
    cat <<-EOF
	$RESOURCES_DIR/foo
	$RESOURCES_DIR/update
EOF
  )
  assertEquals "$expected" "$result"
}

test_find_empty_dirs() {
  local -r test_dir="$RESOURCES_DIR/empty"

  result=$(find_empty_dirs "$RESOURCES_DIR" | sort)
  assertEquals "Before the creation of the empty test directory" "" "$result"

  mkdir -p "$test_dir/dir_test"
  result=$(find_empty_dirs "$RESOURCES_DIR" | sort)
  assertEquals "$test_dir/dir_test" "$result"

  # Clean up
  rm -rf "$test_dir"

  result=$(find_empty_dirs "$RESOURCES_DIR" | sort)
  assertEquals "After the removal of the empty test directory" "" "$result"
}

test_delete_empty_dirs() {
  local -r test_dir="$RESOURCES_DIR/delete_empty_dirs_test"

  mkdir -p "$test_dir/empty_dir_1"
  mkdir -p "$test_dir/empty_dir_2/subdir"
  mkdir -p "$test_dir/non_empty_dir"
  touch "$test_dir/non_empty_dir/file.txt"

  delete_empty_dirs "$test_dir"

  assertFalse "[ -d $test_dir/empty_dir_1 ]"
  assertFalse "[ -d $test_dir/empty_dir_2/subdir ]"
  assertTrue "[ -d $test_dir/non_empty_dir ]"

  # Clean up
  rm -rf "$test_dir"
}

test_ls_files() {
  local result

  result=$(ls_files "$RESOURCES_DIR")
  assertEquals 1 "$(echo "$result" | grep -c 'no_newline_at_the_end.txt' || true)"
  assertEquals 1 "$(echo "$result" | grep -c 'problematic file.sh' || true)"
  assertEquals 0 "$(echo "$result" | grep -c '^d' || true)"
}

test_ls_dirs() {
  local result

  result=$(ls_dirs "$RESOURCES_DIR")
  assertEquals 1 "$(echo "$result" | grep -c 'foo' || true)"
  assertEquals 1 "$(echo "$result" | grep -c 'hello' || true)"
  assertEquals 0 "$(echo "$result" | grep -c 'no_newline_at_the_end.txt' || true)"
  assertEquals 0 "$(echo "$result" | grep -cv '^d' || true)"
}

test_ll_full() {
  local result

  result=$(ll_full "$RESOURCES_DIR/hello")
  assertEquals 1 "$(echo "$result" | head -1 | grep -c 'PERMISSION' || true)"
  assertTrue "[ $(echo "$result" | wc -l) -ge 3 ]"
}

test_ll_part() {
  local result

  result=$(ll_part "$RESOURCES_DIR/hello")
  assertEquals 1 "$(echo "$result" | head -1 | grep -c 'SIZE' || true)"
  assertTrue "[ $(echo "$result" | wc -l) -ge 3 ]"
}

test_ls_file_time() {
  local result

  result=$(ls_file_time "$RESOURCES_DIR/hello")
  assertEquals 1 "$(echo "$result" | head -1 | grep -c 'CREATED' || true)"
  assertTrue "[ $(echo "$result" | wc -l) -ge 2 ]"
}

test_count_ext() {
  local result tmp_dir

  result=$(count_ext "$RESOURCES_DIR/hello")
  assertEquals 1 "$(echo "$result" | grep -c 'EXTENSION' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^md' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^py' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^sh' || true)"

  result=$(count_ext "$RESOURCES_DIR" 2)
  assertEquals 1 "$(echo "$result" | grep -c 'EXTENSION' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^sh.*2' || true)"

  tmp_dir="$(mktemp -d)"
  touch "$tmp_dir/a.sh"
  touch "$tmp_dir/no_extension"
  result=$(count_ext "$tmp_dir")
  rm -rf "$tmp_dir"
  assertEquals 1 "$(echo "$result" | grep -c '^sh.*1' || true)"
  assertEquals 0 "$(echo "$result" | grep -c '^no_extension' || true)"
}

oneTimeSetUp() {
  RESOURCES_DIR="tests/resources/commands"
  mock_file="mock_file.txt"
  touch "$mock_file"
  . core/helpers/gnu_tools.sh # calls 'use_all_gnu_tools'
  . core/helpers/files.sh
}

oneTimeTearDown() {
  rm -f "$mock_file"
  rm -f "${mock_file}.20"*".bkp"
}

. scripts/shunit2
