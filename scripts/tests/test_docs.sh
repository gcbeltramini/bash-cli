#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test_docs.sh [<command_files>]

# Initialize
# --------------------------------------------------------------------------------------------------

command_files=${1:-}

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${CLI_DIR}/core/cli_root/autocomplete_helpers.sh"
source "${TESTS_DIR}/unit_test_helpers.sh"

# Run tests
# --------------------------------------------------------------------------------------------------

if [ -z "$command_files" ]; then
  test_all_commands=true
  command_files=$(get_all_command_files "$CLI_DIR")
else
  test_all_commands=false
fi

command_files=$(echo "$command_files" | sort)

# For debugging:
# echo >&2 -e "[DEBUG] Command files:\n'$command_files'"

new_section_level_2 "Validate documentation"
echo
echo "Validations:"
echo "1. The documentation lines must start with '##?' followed by a space."
echo "2. The 'Usage' section must start with the command name (use additional indentation to split the line)."
echo "3. The 'Options' section must be present if '[options]' is declared in the 'Usage' section."
echo "4. The '--help' parameter must be declared in the 'Options' section if there is another parameter called '--help...'."
echo "5. The length of the lines related to the descriptions of commands, subcommands and options must be less than 150 characters."
echo

commands_path=$(echo "$command_files" | head -n1 | sed -E 's:(.*)/commands/[^/]+/[^/]+\.sh:\1/commands:')
commands_description=$(_mycli_list_commands_and_description "$commands_path")

if $test_all_commands; then
  commands_in_path=$(echo "$command_files" | sed -E "s:$commands_path/::" | cut -d/ -f1 | sort -u)
  if ! [[ "$commands_in_path" == "$(echo "$commands_description" | cut -d':' -f1 | sed -E '/^(update|version)$/d' | sort)" ]]; then
    echo_error "The list of commands in the 'commands' path is different from the list of commands with descriptions."
    echo "Commands in the path '$commands_path':"
    echo "$commands_in_path"
    echo ""
    echo "Commands with descriptions:"
    echo "$commands_description" | sed -E '/^(update|version):/d' | sort
    exit 1
  fi
fi

if commands_no_description=$(grep ':<no description>$' <<<"$commands_description"); then
  echo_error "Some commands do not have a description. Add a description to the following files:"
  echo "$commands_no_description" | cut -d':' -f1 | sort | sed -E 's:(.*):commands/\1/README.md:'
  exit 1
fi

if long_lines=$(grep -E '^.{151,}' <<<"$commands_description"); then
  echo_error "The length of the command name + description must be less than 150 characters. Violations:"
  echo "$long_lines" | sort
  exit 1
fi

prev_command_name=""

while IFS= read -r command_file; do
  command_file_relative_path="${command_file#"$CLI_DIR"/}" # remove the base path and leading '/'

  if grep -E '^##\?' "$command_file" | grep -qE '^##\?[^ ]'; then
    echo_error "The documentation lines must start with a space after '##?' for command '$command_file_relative_path'."
    exit 1
  fi

  # Get the help message for the command
  # help=$(get_help "$command_file") # this is simpler, but '--help' fails when there is a parameter called '--help...',
  # so we will use '--help' instead to test this behavior
  command=$(echo "$command_file" | awk -F'/' '{print $(NF-1) "/" $NF}' | sed 's/\.sh$//')
  cmd1=$(cut -d'/' -f1 <<<"$command")
  cmd2=$(cut -d'/' -f2 <<<"$command")
  help=$("$CLI_DIR/mycli" "$cmd1" "$cmd2" --help)

  usage_lines=$(_mycli_extract_docopt_section "$help" "usage")
  if [ -z "$usage_lines" ]; then
    echo_error "'Usage' section not found for command '$command_file_relative_path' or '--help' did not return the expected output."
    echo "        Checklist:"
    echo "        - Commands in the 'Usage' section must start with spaces."
    echo "        - If there are parameters called '--help...', define the '--help' parameter in the 'Options' section."
    exit 1
  fi

  if wrong_usage=$(echo "$usage_lines" | grep '^  [^ ]' | grep -vE "^  ${cmd1} +${cmd2}"); then
    echo_error "'Usage' must start with the command name ('$cmd1 $cmd2') for command '$command_file_relative_path'."
    echo "If you want to split the usage line, use extra spaces. Offending lines:"
    echo "$wrong_usage"
    exit 1
  fi

  if grep -q '\[options\]' <<<"$usage_lines"; then
    docopt_options=$(_mycli_extract_docopt_section "$help" "options")
    if [ -z "$docopt_options" ]; then
      echo_error "'Options' section not found for command '$command_file_relative_path' ('[options]' is present in the usage line)"
      exit 1
    fi
    # In almost all cases, '--help' shouldn't be declared, but it is necessary when there is another parameter called '--help...'
    # if grep -qE -- '^ *--help( |=|,|$)' <<<"$docopt_options"; then
    #   echo_error "'--help' cannot be declared in the 'Options' section for command '$command_file_relative_path'"
    #   exit 1
    # fi
  fi

  command_name=$(echo "$command_file" | sed -E "s:$commands_path/::" | cut -d/ -f1)
  if [[ "$command_name" != "$prev_command_name" ]]; then
    prev_command_name="$command_name"
    subcommands=$(_mycli_list_subcommands "$commands_path" "$command_name")
    subcommands_description=$(_mycli_list_subcommands_and_description "$commands_path" "$command_name")

    if $test_all_commands; then
      if ! [[ "$(echo "$subcommands" | sort)" == "$(echo "$subcommands_description" | cut -d':' -f1 | sort)" ]]; then
        echo_error "The list of subcommands in the 'commands' directory is different from the list of subcommands with descriptions."
        echo "Subcommands in the path '$commands_path':"
        echo "$subcommands" | sort
        echo ""
        echo "Subcommands with descriptions:"
        echo "$subcommands_description" | sort
        exit 1
      fi
    fi

    if long_lines=$(grep -E '^.{151,}' <<<"$subcommands_description"); then
      echo_error "The length of the subcommand name + description must be less than 150 characters."
      echo "Offending lines for subcommands in command '$command_name':"
      echo "$long_lines" | sort
      exit 1
    fi
  fi

  all_args_with_description=$(_mycli_extract_arguments_with_descriptions "$help" "$cmd1" "$cmd2")
  if long_lines=$(grep -E '^.{151,}' <<<"$all_args_with_description" | grep -v '^:'); then
    echo_error "The length of the options descriptions must be less than 150 characters."
    echo "Offending lines in command '$command_file_relative_path':"
    echo "$long_lines"
    exit 1
  fi

done <<<"$command_files"

echo_done
