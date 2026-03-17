#!/usr/bin/env bash
set -euo pipefail

# TODO: review autocomplete

##? List files or directories in a given path.
##?
##? Usage:
##?   files ls (files | dirs) [<path>]
##?   files ls -l [--short] [<path>]
##?   files ls file-time [<path>]
##?   files ls count-ext [--maxdepth=<d>] [<path>]
##?
##? Options:
##?   <path>          Path to the directory to search for files [default: .]
##?   files           List files in the directory
##?   dirs            List directories in the directory
##?   -l              Similar to 'ls -l', but with better formatting
##?   --short         Select some columns for 'ls -l'
##?   file-time       Display file creation, modification, change and access times
##?   count-ext       Count the number of files with each extension; hidden files are ignored.
##?   --maxdepth=<d>  Maximum depth to search for files when using 'count-ext' [default: 1]

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare count_ext dirs files file_time l maxdepth path short

path=${path:-.}

if $files; then
  ls_files "$path"
elif $dirs; then
  ls_dirs "$path"
elif $l; then
  if $short; then
    ll_part "$path"
  else
    ll_full "$path"
  fi
elif $file_time; then
  ls_file_time "$path"
elif $count_ext; then
  count_ext "$path" "$maxdepth"
fi
