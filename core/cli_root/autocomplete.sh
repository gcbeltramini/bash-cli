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
  local -r docopt_usage=$(echo "$help" | sed -n '/^usage:/I,/^$/p' | sed '$d')
  local -r usage_line=$(echo "$docopt_usage" | grep "^ *$cmd1  *$cmd2 " || :)

  params=""

  # Extract parameters from the "Options" section when "[options]" is declared in the usage line
  if grep -q '\[options\]' <<<"$usage_line"; then
    local -r docopt_options=$(echo "$help" | sed -n '/^options:/I,/^$/p' | sed '$d')
  else
    local -r docopt_options=""
  fi

  # Extract parameters from the usage line
  # - get the parameters that start with a dash, delimited by space, equal sign and comma: "--foo --foo=42" or
  #   "-f, --foo" (only appears in the options)
  # - exclude the 'parameter' "--" and parameters such as "<ls-args>"
  params+=$(echo "$usage_line $docopt_options" |
    grep -o -- '-[^ =,]*' |
    grep -vE '^--$|>' || :)

  # Add "--help" because it's always available and is normally not declared in the usage line
  echo -e "$params\n--help" | sort -u
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

  # Case 3: The user is completing the parameters
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
