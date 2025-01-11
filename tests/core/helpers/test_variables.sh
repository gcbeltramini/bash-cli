#!/usr/bin/env bash
set -euo pipefail

test_show_env_vars() {
    local result
    result=$(show_env_vars "^HOME=|^USER=")
    assertContains "$result" "HOME=/"
    assertContains "$result" "USER="
}

test_show_env_vars_name() {
    local result
    result=$(show_env_vars_name "^HOME=|^USER=")
    assertContains "$result" "HOME"
    assertContains "$result" "USER"
}

test_is_set() {
    # shellcheck disable=SC2034
    local x=12
    assertTrue 'x should be set' 'is_set x'
    unset x
    assertFalse 'x should not be set' 'is_set x'
}

test_is_array() {
    declare -a my_array
    assertTrue \
        'A variable declared as an array should be considered an array' \
        'is_array my_array'

    unset my_array
    # shellcheck disable=SC2034
    my_array=(11 22 33)
    assertTrue \
        'A variable defined as an array should be considered an array' \
        'is_array my_array'

    # shellcheck disable=SC2034
    local -r x=123
    assertFalse 'A numberic value is not an array' 'is_array x'

    assertFalse 'A variable that does not exist is not an array' 'is_array i_dont_exist'

    declare -A my_assoc_array
    assertTrue \
        'A variable declared as an associative array should be considered an array' \
        'is_array my_assoc_array'

    # shellcheck disable=SC2034
    my_assoc_array=(['a']=11 ['b']=22 ['c']=33)
    assertTrue \
        'A variable defined as an associative array should be considered an array' \
        'is_array my_assoc_array'
}

oneTimeSetUp() {
    . core/helpers/variables.sh
}

. scripts/shunit2
