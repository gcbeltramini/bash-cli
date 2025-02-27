#!/usr/bin/env bash
set -euo pipefail

##? Display files that don't have exactly one empty line at the end.
##?
##? Usage:
##?   files end-of-line [<path>]
##?
##? Options:
##?   <path>  Path to the directory to search for files [default: .]

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare path

files_to_check=$(find_relevant_files "${path:-.}")

echo "Files without exactly one empty line at the end:"
found=false
while IFS= read -r file; do
  if ! has_exactly_one_line_at_the_end "$file"; then
    echo "$file"
    found=true
  fi
done < <(printf '%s\n' "$files_to_check")

if [ "$found" = false ]; then
  echo_color "gray" "All files have exactly one empty line at the end."
fi
echo_done
