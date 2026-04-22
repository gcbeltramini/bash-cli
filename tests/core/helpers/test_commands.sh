#!/usr/bin/env bash
set -euo pipefail

test_command_exists() {
  assertTrue 'command_exists ls'
  assertFalse 'command_exists i-dont-exist'
}

test_shell_commands_find() {
  local result

  # Without arguments, returns all available commands (non-empty)
  result=$(shell_commands_find)
  assertNotEquals "" "$result"

  # Finds a known builtin command
  result=$(shell_commands_find '^echo$')
  assertEquals "echo" "$result"

  # Finds this function itself (sourced as a shell function)
  result=$(shell_commands_find '^shell_commands_find$')
  assertEquals "shell_commands_find" "$result"

  # Returns empty for a non-existent command
  result=$(shell_commands_find 'this-command-xyz-doesnt-exist-123abc')
  assertEquals "" "$result"

  # Invalid regex should fail (grep returns error for malformed pattern)
  assertFalse 'shell_commands_find "[" &>/dev/null'
}

oneTimeSetUp() {
  . core/helpers/commands.sh
}

. scripts/shunit2
