#!/usr/bin/env bash
set -euo pipefail

##? This section will not be parsed.
##?
##? Usage:
##?   anything hello-world [<positional-param> --my-param=<x> --some-flag]
##?   anything hello-world many [<names>...]
##?   anything hello-world my-cmd <pos1> <pos2>
##?   anything hello-world (cmd1|cmd2) <pos1> <pos2>
##?
##? Options:
##?   --my-param=<x>  Some parameter [default: 123]
##?
##? Examples:
##?   This section will not be parsed.

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare my_param some_flag many my_cmd pos1 pos2 cmd1 cmd2
declare -a names

if [[ -n "$positional_param" ]]; then
    echo "--my-param='$my_param'"
    echo "--some-flag='$some_flag'"
elif "$many"; then
    index=0
    for name in "${names[@]}"; do
        echo "name ${index} = '$name'"
        index=$((index + 1))
    done
elif "$my_cmd"; then
    echo "pos1='$pos1'"
    echo "pos2='$pos2'"
elif $cmd1 || $cmd2; then
    echo "cmd1='$cmd1'"
    echo "cmd2='$cmd2'"
    echo "pos1='$pos1'"
    echo "pos2='$pos2'"
fi
