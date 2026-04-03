#!/usr/bin/env bash
set -euo pipefail

##? Find commands.
##?
##? Usage:
##?   cmd find [<regex>]
##?
##? Options:
##?   <regex>  Regular expression to filter commands

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare regex

shell_commands_find "$regex"
