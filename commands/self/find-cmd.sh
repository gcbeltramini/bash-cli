#!/usr/bin/env bash
set -euo pipefail

##? Find mycli commands.
##?
##? Usage:
##?   self find-cmd [--command <regex1>] [--subcommand <regex2>]
##?
##? Options:
##?   --command <regex1>     Regular expression to filter commands
##?   --subcommand <regex2>  Regular expression to filter subcommands

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare command subcommand

commands="$(
  find "${CLI_DIR}/commands" -mindepth 2 -maxdepth 2 -type f -name '*.sh' | while read -r command_file; do
    cmd_subcommand=$(echo "$command_file" | awk -F/ '{print $(NF-1) " " $NF}' | sed 's/\.sh$//')
    description=$(grep -m 1 '^##?' "$command_file" | sed 's/^##? *//')
    printf '%s\t-- %s\n' "$cmd_subcommand" "$description"
  done | sort
)"

if [[ -n "$command" ]]; then
  commands="$(printf '%s\n' "${commands}" | awk -F'\t' -v r="$command" '{split($1, a, " "); if (a[1] ~ r) print}')"
fi

if [[ -n "$subcommand" ]]; then
  commands="$(printf '%s\n' "${commands}" | awk -F'\t' -v r="$subcommand" '{split($1, a, " "); if (a[2] ~ r) print}')"
fi

printf '%s\n' "${commands}" | column -t -s $'\t'
