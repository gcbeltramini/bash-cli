#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Find Git repositories with uncommitted changes.
##?
##? Usage:
##?   git local-changes [<path>]
##?
##? Options:
##?   <path>  Path to the directory to search in [default: .]

parse_help "$@"
declare path

path=${path:-.}

echo_progress "Repositories with uncommitted changes:"
find "$path" -type d -name ".git" | while read -r git_dir; do
  repo_dir=$(dirname "$git_dir")
  git_status_output=$(git -C "$repo_dir" status --porcelain)
  if [[ -n "$git_status_output" ]]; then
    echo "$repo_dir"
    # shellcheck disable=SC2001
    echo "$git_status_output" | sed 's/^/  - /'
  fi
done

echo_done
