#!/usr/bin/env bash
set -euo pipefail

command_exists() {
  # Check if a command exists.
  #
  # Usage:
  #   command_exists <cmd>
  #
  # Examples:
  #   if command_exists ls; then echo "Command 'ls' exists."; fi
  #   if command_exists foo; then echo "Command 'foo' does not exist."; fi
  local -r cmd=$1
  command -v "$cmd" >/dev/null
}

shell_commands_find() {
  # Find commands that contain a given regular expression.
  #
  # It is useful to:
  # - Find which commands are available. For example, if you want to find all commands related to "git",
  #   you can use `shell_commands_find git`.
  # - Find which commands are autocompleted, if you search for commands that start with a certain text.
  #
  # Usage:
  #   shell_commands_find [<regex>]
  #
  # Examples:
  #   shell_commands_find        # all commands
  #   shell_commands_find foo    # commands that contain "foo"
  #   shell_commands_find '^bar' # commands that start with "bar"
  #   shell_commands_find 'baz$' # commands that end with "baz"
  #
  # References:
  # - https://unix.stackexchange.com/a/127508
  # - https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html
  local -r regex=${1:-}
  compgen -abck -A function | {
    grep -e "$regex" || {
      local -r status=$?
      if [[ $status -ne 1 ]]; then
        return "$status"
      fi
      return 0
    }
  } | LC_ALL=C sort -u
}
