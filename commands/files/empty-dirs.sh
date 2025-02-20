#!/usr/bin/env bash
set -euo pipefail

##? Find empty directories.
##?
##? Usage:
##?   files empty-dirs [<path> -a]
##?
##? Options:
##?   <path>  Path to the directory to search in [default: .]
##?   -a      Return also folders that contain only hidden files and folders (names beginning with a dot)

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare a path

path=${path:-.}
msg_color="gray"

echo_color >&2 "$msg_color" "Empty directories in '$path':"
find "$path" -type d -empty

if $a; then
  echo_color >&2 "$msg_color" "Directories in '$path' that contain only hidden files and directories:"
  find_dirs_with_only_hidden_files "$path"
fi

echo_done
