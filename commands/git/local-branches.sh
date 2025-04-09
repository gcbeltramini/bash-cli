#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Find Git repositories with local branches.
##?
##? Usage:
##?   git local-branches [<path>]
##?
##? Options:
##?   <path>  Path to the directory to search in [default: .]

parse_help "$@"
declare path

path=${path:-.}

echo_progress "Repositories with local branches:"
find "$path" -type d -name ".git" | while read -r git_dir; do
  repo_dir=$(dirname "$git_dir")
  local_branches=$(git -C "$repo_dir" branch --format="%(refname:short)" | grep -vE '^\*|main|master|develop|DEV' || :)
  if [[ -n "$local_branches" ]]; then
    echo "$repo_dir"
    # shellcheck disable=SC2001
    echo "$local_branches" | sed 's/^/  - /'
  fi
done

echo_done
