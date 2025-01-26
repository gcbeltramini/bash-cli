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
  command_files=$(get_all_command_files "$CLI_DIR")
fi

echo "Validations:"
echo "1. The documentation lines must start with '##?' followed by a space."
echo "2. The 'Usage' section must start with the command name (use additional indentation to split the line)."
echo "3. The 'Options' section must be present if '[options]' is declared in the 'Usage' section."
echo "4. The '--help' parameter must be declared in the 'Options' section if there is another parameter called '--help...'."

while IFS= read -r command_file; do
  command_file_relative_path="${command_file#"$CLI_DIR"/}" # remove the base path and leading '/'

  if grep -E '^##\?' "$command_file" | grep -qE '^##\?[^ ]'; then
    echo "[ERROR] The documentation lines must start with a space after '##?' for command '$command_file_relative_path'."
    exit 1
  fi

  # Get the help message for the command
  # help=$(get_help "$command_file") # this is simpler, but '--help' fails when there is a parameter called '--help...',
  # so we will use '--help' instead to test this behavior
  command=$(echo "$command_file" | awk -F'/' '{print $(NF-1) "/" $NF}' | sed 's/\.sh$//')
  cmd1=$(cut -d'/' -f1 <<<"$command")
  cmd2=$(cut -d'/' -f2 <<<"$command")
  help=$(mycli "$cmd1" "$cmd2" --help)

  usage_lines=$(_mycli_extract_docopt_section "$help" "usage")
  if [ -z "$usage_lines" ]; then
    echo "[ERROR] 'Usage' section not found for command '$command_file_relative_path' or '--help' did not return the expected output."
    echo "        Checklist:"
    echo "        - Commands in the 'Usage' section must start with spaces."
    echo "        - If there are parameters called '--help...', define the '--help' parameter in the 'Options' section."
    exit 1
  fi

  if wrong_usage=$(echo "$usage_lines" | grep '^  [^ ]' | grep -vE "^  ${cmd1} +${cmd2}"); then
    echo "[ERROR] 'Usage' must start with the command name ('$cmd1 $cmd2') for command '$command_file_relative_path'."
    echo "If you want to split the usage line, use extra spaces. Offending lines:"
    echo "$wrong_usage"
    exit 1
  fi

  if grep -q '\[options\]' <<<"$usage_lines"; then
    docopt_options=$(_mycli_extract_docopt_section "$help" "options")
    if [ -z "$docopt_options" ]; then
      echo "[ERROR] 'Options' section not found for command '$command_file_relative_path' ('[options]' is present in the usage line)"
      exit 1
    fi
    # In almost all cases, '--help' shouldn't be declared, but it is necessary when there is another parameter called '--help...'
    # if grep -qE -- '^ *--help( |=|,|$)' <<<"$docopt_options"; then
    #   echo "[ERROR] '--help' cannot be declared in the 'Options' section for command '$command_file_relative_path'"
    #   exit 1
    # fi
  fi
done <<<"$command_files"
