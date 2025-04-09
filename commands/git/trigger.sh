#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Trigger continuous integration (CI) on GitHub repository, such as GitHub Action.
##?
##? This command will make an empty commit and push to the current branch.
##?
##? Usage:
##?   git trigger [--force]

parse_help "$@"
declare force

current_branch="$(git_current_branch)"

if ! $force; then
  if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    exit_with_error "You are on the 'main' or 'master' branch. You should not make commits directly to these branches. To bypass this check, use the '--force' option."
  fi
  confirm "This will make an empty commit and push to the current branch ('$current_branch'). Do you want to continue?"
fi

git commit --allow-empty -m 'Empty commit'
git push origin "$(git_current_branch)"
echo_done
