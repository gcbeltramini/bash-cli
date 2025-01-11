#!/usr/bin/env bash
set -euo pipefail

test_use_gnu_tool() {
    local function_return result

    function_return="dummy function"
    # shellcheck disable=SC2317
    gfoo() { echo "$function_return"; }

    unset -f foo 2>/dev/null
    use_gnu_tool 'gfoo' # will define the function "foo"
    result=$(foo)

    assertEquals "$function_return" "$result"
}

test_use_all_gnu_tools() {
    local function_return result

    # Guarantee that the function 'gdate' is defined
    function_return="dummy function"
    # shellcheck disable=SC2317
    gdate() { echo "$function_return"; }

    unset -f date 2>/dev/null
    use_all_gnu_tools # will define 'date' as 'gdate' (among many other functions, if they exist)
    result=$(date)

    assertEquals "$function_return" "$result"
}

oneTimeSetUp() {
    . core/helpers/gnu_tools.sh
}

. scripts/shunit2
