#!/usr/bin/env bash
set -euo pipefail

test_is_mac() {
    local -r output=$(is_mac)
    assertNull "$output"
    local -r result=$?
    assertTrue "[ $result -eq 0 ] || [ $result -eq 1 ]"
}

test_get_dir_name() {
    local result expected

    result=$(get_dir_name "$PWD")
    expected=$(dirname "$PWD")
    assertEquals "$expected" "$result"

    result=$(get_dir_name "i/do/not/exist")
    expected=''
    assertEquals "$expected" "$result"
}

oneTimeSetUp() {
    . core/helpers/system.sh
}

. scripts/shunit2
