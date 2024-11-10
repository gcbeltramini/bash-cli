#!/usr/bin/env bash
set -o pipefail

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

  # Define possible completions for <cmd1>
  local -r cmds1=$(
    {
      find "$commands_dir" \
        -maxdepth 1 \
        -mindepth 1 \
        -type d \
        -exec basename {} \;
      echo "update"
      echo "version"
    } | sort
  )

  # Define possible completions for <cmd2>
  # The code is the same as the CLI function `list_commands`
  local -r cmds2=$(
    find "$commands_dir" \
      -mindepth 2 \
      -maxdepth 2 \
      -type f \
      -path "${commands_dir}/${prev}*/*" \
      -name "*.sh" \
      -exec basename {} \; |
      sed "s:\.sh$::" |
      sort
  )

  # If the user is completing <cmd1> (the first argument)
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$cmds1" -- "$cur"))
    return 0
  # If the user is completing <cmd2> (the second argument)
  elif [[ ${COMP_CWORD} -eq 2 ]]; then
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$cmds2" -- "$cur"))
    return 0
  fi
}

# Register the autocomplete function
complete -F _mycli_completions mycli
