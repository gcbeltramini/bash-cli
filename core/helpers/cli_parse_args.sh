#!/usr/bin/env bash
set -euo pipefail

get_help() {
    # Get help content of a file.
    #
    # Usage:
    #   get_help <filename>
    local -r filename=$1
    local -r help_line_regex='^##\? ?'
    grep -E "$help_line_regex" "$filename" | sed -E "s/${help_line_regex}//"
}

parse_args() {
    # Parse arguments from help content of a command. The command name `<cmd_name>` is the second
    # word in the `Usage` section`.
    #
    # Usage:
    #   parse_help <help_text> <cmd_name> [<cmd_args>...]
    #
    # Examples:
    #   parse_help "... Usage: hello world ..." "world"
    local -r help_text=$1
    local -r cmd_name=$2
    shift 2
    local -r cmd_args=("$@")

    python3 "${CLI_DIR}/scripts/doc_parser/docopt_runner.py" "$help_text" "$cmd_name" "${cmd_args[@]}"
}

_is_str_to_eval() {
    # Check if this string should be evaluated.
    #
    # Usage:
    #   _is_str_to_eval <text>
    #
    # Examples:
    #   _is_str_to_eval 'export eval_this="foo"'
    #   _is_str_to_eval '# Foo\nexport eval_this="bar"'
    #   _is_str_to_eval '# Foo\n# export do_not_eval_this="bar"'
    local -r text=$1
    [[ $(echo -e "$text" | grep -v '^ *#' | cut -f1 -d' ' | sort -u) == "export" ]]
}

eval_args() {
    # Evaluate parsed arguments by docopt.
    #
    # Usage:
    #   eval_args <str_to_eval>
    local -r args_to_eval=$1

    if _is_str_to_eval "$args_to_eval"; then
        if [[ -n ${MYCLI_DEBUG:-} ]]; then
            debug_var args_to_eval
        fi
        eval "$args_to_eval"
    else
        # This may happen when --help or --version is used
        echo "$args_to_eval"
        exit 0
    fi
}

get_command_name() {
    # Get the command name from filename.
    #
    # Usage:
    #   get_command_name <filename>
    #
    # Examples:
    #   get_command_name 'foo/bar/qwerty.sh' # --> 'qwerty'
    #   get_command_name 'foo/bar/baz' # --> 'baz'
    local -r filename=$1
    basename "$filename" | sed 's/\.sh$//'
}

_parse_help_from_file() {
    # Parse help content of a file into string with arguments and parameters.
    #
    # Usage:
    #   _parse_help_from_file <filename> [<cmd_args>...]
    local -r filename=$1
    shift 1
    local -r cmd_args=("$@")
    local -r help_text="$(get_help "$filename")"
    local -r cmd_name=$(get_command_name "$filename")
    parse_args "$help_text" "$cmd_name" "${cmd_args[@]}"
}

parse_help() {
    # Parse help content of a command and compute input variables and options.
    #
    # Usage:
    #   parse_help [<cmd_args>]
    local -r calling_filename="${BASH_SOURCE[1]}"
    local -r cmd_args=("$@")
    local -r args=$(_parse_help_from_file "$calling_filename" "${cmd_args[@]}")
    eval_args "$args"
}
