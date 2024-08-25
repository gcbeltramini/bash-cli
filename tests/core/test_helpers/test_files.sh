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
