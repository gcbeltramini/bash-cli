#!/usr/bin/env bash
set -euo pipefail

test_command_exists() {
  assertTrue 'command_exists ls'
  assertFalse 'command_exists i-dont-exist'
}

oneTimeSetUp() {
  . core/helpers/commands.sh
}

. scripts/shunit2
