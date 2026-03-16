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

commands_find() {
  # Find commands that contain a given regular expression.
  #
  # It is useful to:
  # - Find which commands are available. For example, if you want to find all commands related to "git",
  #   you can use `commands_find git`.
  # - Find which commands are autocompleted, if you search for commands that start with a certain text.
  #
  # Usage:
  #   commands_find [<regex>]
  #
  # Examples:
  #   commands_find        # all commands
  #   commands_find foo    # commands that contain "foo"
  #   commands_find '^bar' # commands that start with "bar"
  #   commands_find 'baz$' # commands that end with "baz"
  #
  # References:
  # - https://unix.stackexchange.com/a/127508
  # - https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html
  local -r regex=${1:-}
  compgen -abck -A function | grep -e "$regex" | sort | uniq
}
