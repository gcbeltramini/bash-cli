#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Find git repositories with stashed changes.
##?
##? Usage:
##?   git stashed-changes [<path>]
##?
##? Options:
##?   <path>  Path to the directory to search in [default: .]

parse_help "$@"
declare path

path=${path:-.}

echo_gray "Repositories with stashed changes:"
find "$path" -type d -name ".git" -prune -print0 | while IFS= read -r -d $'\0' git_dir; do
  repo_dir=$(dirname "$git_dir")
  if git -C "$repo_dir" stash list | grep -q .; then
    echo "$repo_dir"
  fi
done

echo_done
