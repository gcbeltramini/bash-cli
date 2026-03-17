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

test_find_relevant_files() {
  local result expected

  result=$(find_relevant_files "tests/resources/commands/hello" | LC_ALL=C sort)
  expected=$(
    cat <<-EOF
	tests/resources/commands/hello/README.md
	tests/resources/commands/hello/hello-world.sh
	tests/resources/commands/hello/script.py
EOF
  )
  assertEquals "$expected" "$result"

  result=$(find_relevant_files "tests/resources/commands/hello" -name '*.sh' | sort)
  expected=$(
    cat <<-EOF
	tests/resources/commands/hello/hello-world.sh
EOF
  )
  assertEquals "$expected" "$result"
}

test_files_not_ending_with_newline() {
  local result expected

  result=$(files_not_ending_with_newline "$(find_relevant_files "tests/resources/commands")" | sort)
  expected="tests/resources/commands/no_newline_at_the_end.txt"
  assertEquals "$expected" "$result"

  files=$(
    cat <<-EOF
	tests/resources/commands/no_newline_at_the_end.txt
	tests/resources/commands/problematic file.sh
EOF
  )
  result=$(files_not_ending_with_newline "$files")
  expected="tests/resources/commands/no_newline_at_the_end.txt"
  assertEquals "$expected" "$result"
}

test_has_exactly_one_line_at_the_end() {
  local result
  assertTrue 'has_exactly_one_line_at_the_end "tests/resources/commands/hello/hello-world.sh"'

  assertFalse 'has_exactly_one_line_at_the_end "tests/resources/commands/problematic file.sh"'

  has_exactly_one_line_at_the_end "tests/resources/commands/problematic file.sh"
  result=$?
  assertEquals 2 "$result"

  assertFalse 'has_exactly_one_line_at_the_end "tests/resources/commands/no_newline_at_the_end.txt"'

  has_exactly_one_line_at_the_end "tests/resources/commands/no_newline_at_the_end.txt"
  result=$?
  assertEquals 1 "$result"
}

test_yaml2json() {
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

  result=$(find_dirs_with_only_hidden_files "tests/resources/commands" | sort)
  expected=$(
    cat <<-EOF
	tests/resources/commands/foo
	tests/resources/commands/update
EOF
  )
  assertEquals "$expected" "$result"
}

test_ls_files() {
  local result

  result=$(ls_files "tests/resources/commands")
  assertEquals 1 "$(echo "$result" | grep -c 'no_newline_at_the_end.txt' || true)"
  assertEquals 1 "$(echo "$result" | grep -c 'problematic file.sh' || true)"
  assertEquals 0 "$(echo "$result" | grep -c '^d' || true)"
}

test_ls_dirs() {
  local result

  result=$(ls_dirs "tests/resources/commands")
  assertEquals 1 "$(echo "$result" | grep -c 'foo' || true)"
  assertEquals 1 "$(echo "$result" | grep -c 'hello' || true)"
  assertEquals 0 "$(echo "$result" | grep -c 'no_newline_at_the_end.txt' || true)"
  assertEquals 0 "$(echo "$result" | grep -cv '^d' || true)"
}

test_ll_full() {
  local result

  result=$(ll_full "tests/resources/commands/hello")
  assertEquals 1 "$(echo "$result" | head -1 | grep -c 'PERMISSION' || true)"
  assertTrue "[ $(echo "$result" | wc -l) -ge 3 ]"
}

test_ll_part() {
  local result

  result=$(ll_part "tests/resources/commands/hello")
  assertEquals 1 "$(echo "$result" | head -1 | grep -c 'SIZE' || true)"
  assertTrue "[ $(echo "$result" | wc -l) -ge 3 ]"
}

test_ls_file_time() {
  local result

  result=$(ls_file_time "tests/resources/commands/hello")
  assertEquals 1 "$(echo "$result" | head -1 | grep -c 'CREATED' || true)"
  assertTrue "[ $(echo "$result" | wc -l) -ge 2 ]"
}

test_count_ext() {
  local result tmp_dir

  result=$(count_ext "tests/resources/commands/hello")
  assertEquals 1 "$(echo "$result" | grep -c 'EXTENSION' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^md' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^py' || true)"
  assertEquals 1 "$(echo "$result" | grep -c '^sh' || true)"

  result=$(count_ext "tests/resources/commands" 2)
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
