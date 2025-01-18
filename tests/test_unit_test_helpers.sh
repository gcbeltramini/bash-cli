#!/usr/bin/env bash
set -euo pipefail

test_clean_path_name() {
    local result

    result=$(clean_path_name "/path/to/file")
    assertEquals \
        "When the second argument is empty, return the input path" \
        "/path/to/file" \
        "$result"

    result=$(clean_path_name "/path/to/file" "")
    assertEquals \
        "When the second argument is empty, return the input path" \
        "/path/to/file" \
        "$result"

    result=$(clean_path_name "/path/to/my/file" "/path/to/")
    assertEquals "my/file" "$result"

    result=$(clean_path_name "/path/to/my/file" "to/my/")
    assertEquals "Remove path from the beginning" "/path/to/my/file" "$result"
}

test_check_if_error() {
    # shellcheck disable=SC2034
    CLI_DIR="/path/to/cli/"

    local result expected

    result=$(check_if_error "")
    assertEquals "OK!" "$result"

    result=$(check_if_error "" "Error message")
    assertEquals "OK!" "$result"

    result=$(check_if_error "/path/to/cli/command/file1\n/path/to/cli/file2" 2>&1)
    expected=$(cat <<-EOF
	\033[31m[ERROR]\033[0m Invalid files:
	command/file1
	file2
EOF
    )
    assertEquals "$(echo -e "$expected")" "$result"

    result=$(check_if_error "/another/path/file1\nfile2" "Error message:" 2>&1)
    expected=$(cat <<-EOF
	\033[31m[ERROR]\033[0m Error message:
	/another/path/file1
	file2
EOF
    )
    assertEquals "$(echo -e "$expected")" "$result"
}

test_has_invalid_shebang() {
    assertTrue 'has_invalid_shebang "#!/foo/bar " "tests/resources/commands/hello-world.sh"'
    assertFalse 'has_invalid_shebang "#!/usr/bin/env " "tests/resources/commands/hello-world.sh"'
}

test_has_invalid_set() {
    assertTrue 'has_invalid_set "set -e" "tests/resources/commands/hello-world.sh"'
    assertFalse 'has_invalid_set "set -euo pipefail" "tests/resources/commands/hello-world.sh"'
}

test_has_shellcheck_all_disabled() {
    assertTrue 'has_shellcheck_all_disabled "core/helpers/constants.sh"'
}

test_find_not_executable() {
    local result

    result=$(find_not_executable "tests/resources")
    assertEquals "tests/resources/commands/problematic file.sh" "$result"
}

test_find_forbidden_cmd_names() {
    local result expected

    result=$(find_forbidden_cmd_names "tests/resources" | sort)
    expected=$(cat <<-EOF
	tests/resources/commands/problematic file.sh
	tests/resources/commands/update
EOF
    )
    assertEquals "$expected" "$result"
}

test_get_variable_def_or_fn_call() {
    local result

    result=$(get_variable_def_or_fn_call "tests/resources/commands/problematic file.sh")
    assertEquals "" "$result"

    result=$(get_variable_def_or_fn_call "$0")
    assertEquals ". scripts/shunit2" "$result"
}

oneTimeSetUp() {
    . tests/unit_test_helpers.sh
}

. scripts/shunit2
