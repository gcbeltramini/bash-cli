#!/usr/bin/env bash
set -euo pipefail

# Helper functions used by the CLI directly, and only by the CLI. No command should use these functions.

run_command() {
  # Run CLI command.
  #
  # Usage:
  #   run_command <cmd1> <cmd2> [<cmd_args>...]
  #
  # Examples:
  #
  #   # Help:
  #   run_command help hello
  #   run_command hello --help
  #   run_command hello -h
  #   run_command help hello world
  #   run_command hello world --help
  #   run_command hello world -h
  #
  #   run_command hello world
  #   run_command hel wor # if prefixes are unique, it is the same as: run_command hello world
  local -r cmd1=$1
  local -r cmd2=$2
  shift 2
  local -r cmd_args=("$@")

  if [[ $cmd1 == 'help' ]]; then
    if [[ ${#cmd_args[@]} -eq 0 ]]; then
      # mycli help <command>
      list_commands "$cmd2" >&2
      exit 0
    else
      # mycli help <command> <subcommand>
      run_command "$cmd2" "${cmd_args[@]}" --help
      exit 0
    fi
  elif [[ $cmd2 == '--help' || $cmd2 == '-h' ]]; then
    # mycli <command> --help
    # mycli <command> -h
    list_commands "$cmd1" >&2
    exit 0
  fi

  local -r commands_dir="${CLI_DIR}/commands"
  local -r command_path=$(find "$commands_dir" \
    -type f \
    -maxdepth 2 \
    -path "${commands_dir}/${cmd1}*/*" \
    -name "${cmd2}*.sh")

  local -r no_color='\x1b[0m'
  local -r color_red='\x1b[31m'
  local -r color_blue='\x1b[34m'

  if [[ -z $command_path ]]; then
    # The command was not found.
    local -r asterisk="${color_blue}*${no_color}"
    echo >&2 -e "${color_red}ERROR:${no_color} It was not possible to find the command '${cmd1} ${cmd2}'."
    echo >&2 -e "       Make sure that the following path exists: '${commands_dir}/${cmd1}${asterisk}/${cmd2}${asterisk}.sh'"
    echo >&2 -e "       ('${asterisk}' denote 0 or more characters in the path above)"
    echo >&2
    list_commands "$cmd1" >&2
    exit 1
  elif (($(echo "$command_path" | wc -l) == 1)); then
    # Exactly one command was found. This is the happy path.
    "$command_path" "${cmd_args[@]}"
  else
    # More than one command was found.
    local -r command_path_exact=$(echo "$command_path" | grep "${cmd2}.sh$")
    if [[ -n $command_path_exact ]]; then # 'cmd2' is a substring of another command, but it's an exact match of an existing command
      # Example: 'git check' and 'git checkout' (cm1='git', cmd='check')
      "$command_path_exact" "${cmd_args[@]}"
    else
      echo >&2 -e "${color_red}ERROR:${no_color} It was not possible to distinguish the commands."
      echo >&2
      echo >&2 "Ambiguous commands"
      echo >&2 "------------------"
      echo "$command_path" |
        sed "s:${commands_dir}/:: ; s:\.sh$::" |
        tr '/' ' ' |
        sort
      exit 1
    fi
  fi
}

list_commands() {
  # List available CLI commands with their descriptions.
  #
  # The output is sorted alphabetically and aligned in columns with the delimiter "--", just like the
  # output of the autocomplete of the `brew` and `git` commands.
  #
  # Usage:
  #   list_commands [<cmd>]
  local -r cmd=${1:-}
  local -r commands_dir="${CLI_DIR}/commands"

  local -r update_description="Update the CLI."
  local -r version_description="Show the CLI version."

  if [[ -z $cmd ]]; then
    echo "Available commands"
    echo "------------------"
    {
      find "$commands_dir" -mindepth 2 -maxdepth 2 -type f -name "*.sh" | while read -r command_file; do
        cmd_subcommand=$(echo "$command_file" | awk -F/ '{print $(NF-1) " " $NF}' | sed 's/\.sh$//')
        # first line starting with "##?":
        description=$(grep -m 1 '^##?' "$command_file" | sed 's/^##? *//')
        echo -e "$cmd_subcommand\t-- $description"
      done
      echo -e "update\t-- $update_description"
      echo -e "version\t-- $version_description"
    } | sort | column -t -s $'\t'
  else
    if [[ $cmd == "update" ]]; then
      cat <<-EOF
	$update_description

	Usage:
	  mycli update
EOF
      return 0
    elif [[ $cmd == "version" ]]; then
      cat <<-EOF
	$version_description

	Usage:
	  mycli version
EOF
      return 0
    fi

    echo "Available commands for '$cmd'"
    local -r dashes=$(printf '%*s' "${#cmd}" '' | tr ' ' '-')
    echo "-------------------------${dashes}"
    find "$commands_dir" \
      -mindepth 2 \
      -maxdepth 2 \
      -type f \
      -path "${commands_dir}/${cmd}*/*" \
      -name "*.sh" | while read -r command_file; do
      subcommand=$(echo "$command_file" | awk -F/ '{print $NF}' | sed 's/\.sh$//')
      # first line starting with "##?":
      description=$(grep -m 1 '^##?' "$command_file" | sed 's/^##? *//')
      echo -e "$subcommand\t-- $description"
    done | sort | column -t -s $'\t'
  fi
}

show_cli_help() {
  # Show CLI help.
  #
  # Usage:
  #   show_cli_help
  echo 'Welcome to the CLI (command-line interface)!'
  echo
  echo 'Usage'
  echo '-----'
  echo '  mycli <command> <subcommand> [<args>]'
  echo
  echo "Run 'mycli help <command>' or 'mycli <command> --help' for more information on a command."
  echo
  echo "Run 'mycli help <command> <subcommand>' or 'mycli <command> <subcommand> --help' for more information on a subcommand."
  echo
  list_commands
}
