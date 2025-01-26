#!/usr/bin/env bash
set -o pipefail

source "${MYCLI_HOME}/core/cli_root/autocomplete_helpers.sh"

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
