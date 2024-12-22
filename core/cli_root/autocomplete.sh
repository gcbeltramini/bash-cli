#!/usr/bin/env bash
set -o pipefail

_list_commands() {
  # List all commands available in the CLI.
  #
  # Usage:
  #   _list_commands <commands_dir>
  #
  # Examples:
  #   _list_commands "$MYCLI_HOME/commands" # --> "hello update version"
  local -r commands_dir="$1"

  {
    find "$commands_dir" \
      -maxdepth 1 \
      -mindepth 1 \
      -type d \
      -exec basename {} \;
    echo "update"
    echo "version"
  } | sort
}

_list_subcommands() {
  # List all subcommands available in the CLI.
  #
  # Usage:
  #   _list_subcommands <commands_dir> <command>
  #
  # Examples:
  #   _list_subcommands "$MYCLI_HOME/commands" "hello" # --> "world"
  local -r commands_dir="$1"
  local -r command="$2"

  # Part of this code is the same as the CLI function `list_commands`
  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name "*.sh" \
    -exec basename {} \; |
    sed "s:\.sh$::" |
    sort
}

_extract_docopt_section() {
  # Extract a section from the help message of a command.
  #
  # Usage:
  #   _extract_docopt_section <help> <section>
  #
  # Examples:
  #   _extract_docopt_section "$help" "usage" # --> "Usage: ..."
  local -r help="$1"
  local -r section="$2"
  echo "$help" | sed -n "/^$section:/I,/^$/p" | sed '$d'
}

_find_usage_line() {
  # Find the usage line in the help message of a command.
  #
  # Usage:
  #   _find_usage_line <help> <cmd1> <cmd2>
  #
  # Examples:
  #   _find_usage_line "$help" "hello" "world" # --> "hello world ..."
  local -r help="$1"
  local -r cmd1="$2"
  local -r cmd2="$3"

  local -r docopt_usage=$(_extract_docopt_section "$help" "usage")
  echo "$docopt_usage" | grep "^ *$cmd1  *$cmd2 " || :
}

_extract_parameters() {
  # Extract the parameters from the usage of a command.
  #
  # Usage:
  #   _extract_parameters <usage>
  #
  # Examples:
  #   _extract_parameters "$usage" # --> "--foo --help --some-flag"
  local -r usage="$1"

  # Extract the parameters:
  # - get the parameters that start with a dash, delimited by space, equal sign and comma: "--foo --foo=42" or
  #   "-f, --foo" (only appears in the options)
  # - exclude the 'parameter' "--" and parameters such as "<ls-args>"
  echo "$usage" |
    grep -o -- '-[^ =,]*' |
    grep -vE '^--$|>' || :
}

_extract_additional_commands() {
  # Extract additional commands from the usage of a command.
  #
  # Usage:
  #   _extract_additional_commands <usage_line>
  #
  # Examples:
  #   _extract_additional_commands "$usage_line" # --> "foo ..."
  local -r usage_line="$1"

  echo "$usage_line" |
    sed 's/[\[<-].*//' | # remove everything after '[', '<' or '-'
    grep -o -- '[^ ]*' | # extract words
    tail -n +3 || : # remove the first two words
}

_extract_arguments() {
  # Extract the arguments from the help message of a command. The help content must follow the
  # docopt format.
  #
  # Usage:
  #   _extract_arguments <cmd1> <cmd2>
  #
  # Examples:
  #   _extract_arguments "hello" "world" # --> "--foo --help --some-flag"
  local -r cmd1="$1"
  local -r cmd2="$2"

  # Extract help message
  local -r help=$(mycli "$cmd1" "$cmd2" --help)

  # Extract usage from the help message
  local -r usage_line=$(_find_usage_line "$help" "$cmd1" "$cmd2")

  # Extract the "Options" section when "[options]" is declared in the usage line
  if grep -q '\[options\]' <<<"$usage_line"; then
    local -r docopt_options=$(_extract_docopt_section "$help" "options")
  else
    local -r docopt_options=""
  fi

  # Extract parameters from the usage line and possibly the "Options" section
  params=$(_extract_parameters "$usage_line $docopt_options")

  # Extract additional commands from the usage line
  additional_commands=$(_extract_additional_commands "$usage_line")

  # Add "--help" because it's always available and is normally not declared in the usage line
  echo -e "$params\n$additional_commands\n--help" | sort -u
}

_mycli_completions() {
  # Autocomplete function for the CLI.
  #
  # This function is called by the autocomplete system when the user presses the TAB key.
  # It autocompletes the first and second arguments of the CLI:
  #   mycli <cmd1> <cmd2>
  local -r cur="${COMP_WORDS[COMP_CWORD]}"
  local -r prev="${COMP_WORDS[COMP_CWORD - 1]}"
  local -r commands_dir="${MYCLI_HOME}/commands"

  if [ ! -d "$commands_dir" ]; then
    return 0
  fi

  # Case 1: The user is completing <cmd1> (the first argument)
  if [[ $COMP_CWORD -eq 1 ]]; then
    # Define possible completions for <cmd1>
    local -r cmds1=$(_list_commands "$commands_dir")
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$cmds1" -- "$cur"))
    return 0

  # Case 2: The user is completing <cmd2> (the second argument)
  elif [[ $COMP_CWORD -eq 2 ]]; then
    # Define possible completions for <cmd2>
    local -r cmds2=$(_list_subcommands "$commands_dir" "$prev")
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$cmds2" -- "$cur"))
    return 0

  # Case 3: The user is completing the parameters or other commands
  else
    local args
    args="$(_extract_arguments "${COMP_WORDS[1]}" "${COMP_WORDS[2]}")"

    # Remove arguments that were already typed by the user
    for ((i = 3; i < COMP_CWORD; i++)); do
      args=$(grep -v "^${COMP_WORDS[i]}" <<<"$args")
    done

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$args" -- "$cur"))
    return 0
  fi
}

# Register the autocomplete function
complete -F _mycli_completions mycli
