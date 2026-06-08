#!/usr/bin/env bash
set -euo pipefail

##? Display the source code of a command.
##?
##? Usage:
##?   self source-code <command> <subcommand>
##?
##? Options:
##?   <command>     Command name
##?   <subcommand>  Subcommand name

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare command subcommand

# Validate that command/subcommand contain only safe characters (no path traversal or globs)
if [[ ! $command =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  exit_with_error "Invalid command name: '$command'. Use lowercase letters, numbers, hyphens, and underscores only."
fi
if [[ ! $subcommand =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  exit_with_error "Invalid subcommand name: '$subcommand'. Use lowercase letters, numbers, hyphens, and underscores only."
fi

# Resolve file using find to enforce "commands/" boundary (prevents ../.. and glob escapes)
script_path=$(find "${CLI_DIR}/commands" \
  -maxdepth 2 \
  -type f \
  -path "${CLI_DIR}/commands/${command}/${subcommand}.sh")

if [[ -z $script_path ]]; then
  exit_with_error "Command 'mycli $command $subcommand' not found."
fi

echo_gray "Source code for 'mycli $command $subcommand' (file '$script_path'):\n"

if command_exists "bat"; then
  bat --style=plain --color=auto --language=bash "$script_path"
else
  cat "$script_path"
fi
