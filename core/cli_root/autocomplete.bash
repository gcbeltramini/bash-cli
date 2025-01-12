#!/usr/bin/env bash
set -o pipefail

_mycli_list_commands() {
  # List all commands available in the CLI.
  #
  # Usage:
  #   _mycli_list_commands <commands_dir>
  #
  # Examples:
  #   _mycli_list_commands "$MYCLI_HOME/commands" # --> "hello update version"
  local -r commands_dir=$1

  find "$commands_dir" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -exec basename {} \;
  echo "update"
  echo "version"
}

_mycli_list_subcommands() {
  # List all subcommands available in the CLI.
  #
  # Usage:
  #   _mycli_list_subcommands <commands_dir> <command>
  #
  # Examples:
  #   _mycli_list_subcommands "$MYCLI_HOME/commands" "hello" # --> "world"
  local -r commands_dir=$1
  local -r command=$2

  # Part of this code is the same as the CLI function `list_commands`
  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name "*.sh" \
    -exec basename {} \; |
    sed "s:\.sh$::"
}

_mycli_extract_docopt_section() {
  # Extract a section from the help message of a command (the section name is not returned).
  #
  # Usage:
  #   _mycli_extract_docopt_section <help> <section>
  #
  # Examples:
  #   _mycli_extract_docopt_section "$help" "usage"
  #   _mycli_extract_docopt_section "$help" "options"
  local -r help=$1
  local -r section=$2
  echo "$help" | sed -n "/^$section:/I,/^$/p" | sed '$d' | tail -n +2
}

_mycli_find_usage_lines() {
  # Find the usage line in the help message of a command.
  #
  # Usage:
  #   _mycli_find_usage_lines <help> <cmd1> <cmd2>
  #
  # Examples:
  #   _mycli_find_usage_lines "$help" "hello" "world" # --> "hello world ..."
  local -r help=$1
  local -r cmd1=$2
  local -r cmd2=$3

  local -r docopt_usage=$(_mycli_extract_docopt_section "$help" "usage")
  echo "$docopt_usage" | grep "^ *$cmd1  *$cmd2 " || :
}

_mycli_extract_parameters() {
  # Extract the parameters from the usage of a command.
  #
  # Usage:
  #   _mycli_extract_parameters <usage>
  #
  # Examples:
  #   _mycli_extract_parameters "$usage" # --> "--foo --help --some-flag"
  local -r usage=$1

  # Extract the parameters that:
  # - start with a dash ("-")
  # - are not preceded by any of "[a-zA-Z0-9_<" ("[" must appear in the beginning of the negation "[^...]")
  # - end before any of "] =,": "--foo --foo=42 --bar]" or "-f, --foo" (only appears in the options)
  # - exclude the 'parameter' "--"
  echo "$usage" |
    grep -oE -- '[^[a-zA-Z0-9_<]-[^] =,]+' |
    sed 's/^[[:space:]]*//' |
    grep -vE '^--$' || :
}

_mycli_extract_additional_commands() {
  # Extract additional commands from the usage of a command.
  #
  # Usage:
  #   _mycli_extract_additional_commands <usage_lines>
  #
  # Examples:
  #   _mycli_extract_additional_commands "$usage_lines" # --> "foo ..."
  local -r usage_line=$1

  echo "$usage_line" |
    sed 's/^[[:space:]]*//' |                       # remove spaces from the beginning
    cut -d' ' -f3- |                                # remove the first two words
    tr '[]()|' ' ' |                                # replace brackets, parentheses and pipes with spaces
    grep -o -- '[^ ]*' |                            # extract words
    sed 's/^[<-].*$// ; s/^options$// ; /^$/d' || : # remove parameters and empty lines
}

_mycli_extract_arguments() {
  # Extract the arguments from the help message of a command. The help content must follow the
  # docopt format.
  #
  # Usage:
  #   _mycli_extract_arguments <help> <cmd1> <cmd2>
  #
  # Examples:
  #   _mycli_extract_arguments "$help" "hello" "world" # --> "--foo --help --some-flag abc"
  local -r help=$1
  local -r cmd1=$2
  local -r cmd2=$3

  # Add "--help" because it's always available and is normally not declared in the usage line
  local -r help_param="--help"

  # Extract usage from the help message
  local -r usage_lines=$(_mycli_find_usage_lines "$help" "$cmd1" "$cmd2")

  if [[ -z "$usage_lines" ]]; then
    echo "$help_param"
    return 0
  fi

  # Extract the "Options" section when "[options]" is declared in the usage line
  if grep -q '\[options\]' <<<"$usage_lines"; then
    local -r docopt_options=$(_mycli_extract_docopt_section "$help" "options")
  else
    local -r docopt_options=""
  fi

  # Extract parameters from the usage line and possibly the "Options" section
  local -r params=$(_mycli_extract_parameters "$usage_lines $docopt_options")

  # Extract additional commands from the usage line
  local -r additional_commands=$(_mycli_extract_additional_commands "$usage_lines")

  echo -e "$params\n$additional_commands\n$help_param"
}

_mycli_completions() {
  # Autocomplete function for the CLI.
  #
  # This function is called by the autocomplete system when the user presses the TAB key.
  # It autocompletes the first and second arguments of the CLI, possible additional commands and
  # parameters:
  #   mycli <cmd1> <cmd2> <cmd3>... --param1 ...
  local -r cur=${COMP_WORDS[COMP_CWORD]}
  local -r prev=${COMP_WORDS[COMP_CWORD - 1]}
  local -r commands_dir="${MYCLI_HOME}/commands"

  if [ ! -d "$commands_dir" ]; then
    return 0
  fi

  # Case 1: The user is completing <cmd1> (the first argument)
  if [[ $COMP_CWORD -eq 1 ]]; then
    # Define possible completions for <cmd1>
    local -r cmds1=$(_mycli_list_commands "$commands_dir")

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$cmds1" -- "$cur"))
    return 0

  # Case 2: The user is completing <cmd2> (the second argument)
  elif [[ $COMP_CWORD -eq 2 ]]; then

    if [[ $prev = "update" || $prev = "version" ]]; then
      return 0
    fi

    # Define possible completions for <cmd2>
    local -r cmds2=$(_mycli_list_subcommands "$commands_dir" "$prev")

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$cmds2" -- "$cur"))
    return 0

  # Case 3: The user is completing the parameters or other commands
  else
    local -r help=$(mycli "${COMP_WORDS[1]}" "${COMP_WORDS[2]}" --help)
    local -r all_args=$(_mycli_extract_arguments "$help" "${COMP_WORDS[1]}" "${COMP_WORDS[2]}")

    # Remove arguments that were already typed by the user
    local args=$all_args
    for ((i = 3; i < COMP_CWORD; i++)); do
      args=$(grep -v "^${COMP_WORDS[i]}" <<<"$args")
    done

    if [[ -z "$args" ]]; then
      # No completions available
      return 0
    fi

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$args" -- "$cur"))
    return 0
  fi
}

# Register the autocomplete function
complete -F _mycli_completions mycli
