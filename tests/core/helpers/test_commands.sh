#!/usr/bin/env bash
set -euo pipefail

test_command_exists() {
  assertTrue 'command_exists ls'
  assertFalse 'command_exists i-dont-exist'
}

test_commands_find() {
  local result

  # Without arguments, returns all available commands (non-empty)
  result=$(commands_find)
  assertNotEquals "" "$result"

  # Finds a known builtin command
  result=$(commands_find '^echo$')
  assertEquals "echo" "$result"

  # Finds this function itself (sourced as a shell function)
  result=$(commands_find '^commands_find$')
  assertEquals "commands_find" "$result"

  # Returns empty for a non-existent command
  result=$(commands_find 'this-command-xyz-doesnt-exist-123abc' || true)
  assertEquals "" "$result"
}

oneTimeSetUp() {
  . core/helpers/commands.sh
}

. scripts/shunit2
