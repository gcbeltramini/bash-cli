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

    # result=$(find_relevant_files "tests/resources/commands" | xargs -0 -n 1 echo | sort)
    result=$(find_relevant_files "tests/resources/commands" | sort)
    expected=$(cat <<-EOF
	tests/resources/commands/hello/hello-world.sh
	tests/resources/commands/no_newline_at_the_end.txt
	tests/resources/commands/problematic file.sh
	tests/resources/commands/update/.gitkeep
EOF
    )
    assertEquals "$expected" "$result"

    result=$(find_relevant_files "tests/resources/commands" -name '*.sh' | sort)
    expected=$(cat <<-EOF
	tests/resources/commands/hello/hello-world.sh
	tests/resources/commands/problematic file.sh
EOF
    )
    assertEquals "$expected" "$result"
}

test_files_not_ending_with_newline() {
    local result expected

    result=$(files_not_ending_with_newline "$(find_relevant_files "tests/resources/commands")" | sort)
    expected="tests/resources/commands/no_newline_at_the_end.txt"
    assertEquals "$expected" "$result"

    files=$(cat <<-EOF
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

oneTimeSetUp() {
    mock_file="mock_file.txt"
    touch "$mock_file"
    . core/helpers/files.sh
}

oneTimeTearDown() {
    rm -f "$mock_file"
    rm -f "${mock_file}.20"*".bkp"
}

. scripts/shunit2
