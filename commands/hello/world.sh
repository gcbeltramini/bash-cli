#!/usr/bin/env bash
set -euo pipefail

##? Show hello world message.
##?
##? Usage:
##?   hello world [<name> --foo=NAMED_PARAM --some-flag -- <ls-args>...]
##?
##? Options:
##?   -f, --foo=NAMED_PARAM  Some named parameter [default: 42]
##?   --some-flag            Some flag
##?   <ls-args>              Arguments to pass to 'ls'
##?
##? Examples:
##?   hello world
##?   hello world John
##?   hello world 'John Doe'
##?
##?   # Passing arguments to another command
##?   hello world -- -l -a

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare foo hello_name name some_flag
declare -a ls_args

if [ -n "$name" ]; then
    hello_name=", $name"
else
    hello_name=""
fi

echo_color "green" "Hello from the CLI${hello_name} :)"
echo "The flag '--some-flag' is '${some_flag}'"
echo "The named parameter '--foo' is '${foo}'"

if [ ${#ls_args[@]} -gt 0 ]; then
    echo "Running 'ls' with the following arguments: ${ls_args[*]}"
    ls "${ls_args[@]}"
fi

echo_color "green" "If you can see this green message, it means that the CLI is working on your machine."
