#!/usr/bin/env bash
set -euo pipefail

git_current_branch() {
  # Get the current branch of git repository.
  #
  # Usage:
  #   git_current_branch [<folder>]
  local -r folder=${1:-$PWD}
  git -C "$folder" branch --show-current
  # or:
  # git -C "$folder" rev-parse --abbrev-ref HEAD
}
