#!/usr/bin/env bash
set -euo pipefail

##? Run Python script.
##?
##? Usage:
##?   hello python-script [<name> --foo=NAMED_PARAM --some-flag -- <extra-args>...]
##?
##? Options:
##?   -f, --foo=NAMED_PARAM  Some named parameter [default: 42]
##?   --some-flag            Some flag
##?   <extra-args>           Extra arguments to pass to the Python script
##?
##? Examples:
##?   hello python-script
##?   hello python-script John
##?   hello python-script 'John Doe'
##?   hello python-script --foo=37 --some-flag
##?
##?   # Passing extra arguments
##?   hello python-script Jane -- -l -a

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare foo name some_flag
declare -a extra_args

current_dir="$(get_dir_name "${BASH_SOURCE[0]}")"

echo "Running Python script..."
run_python_script "$current_dir/script.py" --foo="$foo" --some-flag="$some_flag" "$name" "${extra_args[@]}"
echo_done
