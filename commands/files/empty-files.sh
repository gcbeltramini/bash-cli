#!/usr/bin/env bash
set -euo pipefail

##? Find empty files.
##?
##? Usage:
##?   files empty-files [<path>]
##?
##? Options:
##?   <path>  Path to the directory to search in [default: .]

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare path

path=${path:-.}
msg_color="gray"

echo_color >&2 "$msg_color" "Empty files in '$path':"
find "$path" -type f -empty

echo_done
