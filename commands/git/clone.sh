#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Clone GitHub repository.
##?
##? Usage:
##?   git clone <org_name> <repo_name> [<destination_dir>]
##?
##? Examples:
##?   git clone my-org my-cool-repo
##?   git clone my-username my-cool-repo ~/Documents/Projects

parse_help "$@"
declare destination_dir org_name repo_name

if [[ -z $destination_dir ]]; then
  default_destination_dir="$(dirname "$(dirname "$MYCLI_HOME")")/$org_name"
fi
destination_dir="${destination_dir:-$default_destination_dir}"

git clone "git@github.com:${org_name}/${repo_name}.git" "$destination_dir/$repo_name"
echo_done
