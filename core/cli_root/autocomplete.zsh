#!/usr/bin/env zsh
set -o pipefail

source "${MYCLI_HOME}/core/cli_root/autocomplete_helpers.sh"

_mycli_completions() {
  # Autocomplete function for the CLI.
  #
  # This function is called by the autocomplete system when the user presses the TAB key.
  # It autocompletes the first and second arguments of the CLI, possible additional commands and
  # parameters:
  #   mycli <cmd1> <cmd2> <cmd3>... --param1 ...
  local -r cur=${words[CURRENT]}
  local -r prev=${words[CURRENT - 1]}
  local -r commands_dir="${MYCLI_HOME}/commands"

  if [ ! -d "$commands_dir" ]; then
    return 0
  fi

  # Case 1: The user is completing <cmd1> (the first argument)
  if ((CURRENT == 2)); then
    # Define possible completions for <cmd1>

    # shellcheck disable=SC2034,SC2207
    local -ra cmds1=($(_mycli_list_commands "$commands_dir"))
    # shellcheck disable=SC2207
    # compadd -X "Available commands:" -a cmds1
    _describe 'mycli commands' cmds1
    return 0

  # Case 2: The user is completing <cmd2> (the second argument)
  elif ((CURRENT == 3)); then

    if [[ $prev = "update" || $prev = "version" ]]; then
      return 0
    fi

    # Define possible completions for <cmd2>
    local -r cmds_descriptions=$(_mycli_list_subcommands_and_description "$commands_dir" "$prev")

    # Convert the multiline string to an array
    local -ra cmds_descriptions_array=("${(f)cmds_descriptions}")

    _describe 'mycli subcommands' cmds_descriptions_array
    return 0

  # Case 3: The user is completing the parameters or other commands
  else
    local -r help=$(mycli "${words[2]}" "$words[3]" --help)
    local -r all_args_with_description=$(_mycli_extract_arguments_with_descriptions "$help" "${words[2]}" "$words[3]")

    # Remove arguments that were already typed by the user
    local args_with_description=$all_args_with_description
    for word in "${words[@]}"; do
      args_with_description=$(echo "$args_with_description" | sed "/^$word:/d")
    done

    if [[ -z "$args_with_description" ]]; then
      # No completions available
      return 0
    fi

    # Convert the multiline string to an array
    local -ra args_with_description_array=("${(f)args_with_description}")
    _describe 'mycli parameters' args_with_description_array
    return 0
  fi
}

# Only define compdef if running in Zsh
if [[ -n ${ZSH_VERSION:-} ]]; then
    compdef _mycli_completions mycli
fi
