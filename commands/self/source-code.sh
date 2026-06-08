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

script_path="${CLI_DIR}/commands/${command}/${subcommand}.sh"

if [[ ! -f "$script_path" ]]; then
  exit_with_error "Command '$command $subcommand' not found in '${script_path}'."
fi

echo_gray "Source code for 'mycli $command $subcommand' (file '$script_path'):\n"

if command_exists "bat"; then
  bat --style=plain --color=always --language=bash "$script_path"
else
  cat "$script_path"
fi
