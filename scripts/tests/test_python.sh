#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test_python.sh [<python_scripts>]

# Initialize
# --------------------------------------------------------------------------------------------------

python_scripts=${1:-}

CUR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CLI_DIR=$(realpath "${CUR_DIR}/../..")
TESTS_DIR="${CLI_DIR}/tests"

source "${TESTS_DIR}/unit_test_helpers.sh"

# Run tests
# --------------------------------------------------------------------------------------------------

if [ -z "$python_scripts" ]; then
  python_scripts=$(find "$CLI_DIR/commands" -type f -name '*.py')
  # Maybe filter for files containing `if __name__ == "__main__":`. In this case, create a helper
  # function in file `tests/unit_test_helpers.sh`.
fi

# For debugging:
# echo >&2 -e "[DEBUG] Python scripts:\n'$python_scripts'"

new_section_level_2 "All Python scripts should have metadata (PEP 723)"
# https://packaging.python.org/en/latest/specifications/inline-script-metadata/
# Only scripts called after the pattern `^[^#]*run_python_script ` should be verified, but it may not
# be easy to find the name of the script, because it may be defined by a variable or a function.
invalid_files_metadata=''
total_files=$(echo "$python_scripts" | wc -l | xargs)
if [ "$total_files" -eq 1 ]; then plural=''; else plural='s'; fi
echo "Checking $total_files Python file$plural..."
while IFS= read -r python_script; do
  if ! python3 "$TESTS_DIR/python/read_script_metadata.py" "$python_script" >/dev/null; then
    echo
    invalid_files_metadata+="\n$python_script"
  fi
done <<<"$python_scripts"
check_if_error "$invalid_files_metadata"

if ! command -v uv >/dev/null; then
  new_section_level_2 "Creating virtual environment for the next tests"
  venv_name=".venv_pytest"
  python3 -m venv "$venv_name"
  source "$venv_name/bin/activate"
  echo
  echo "Installing 'pytest' and 'ruff'..."
  python3 -m pip install 'pytest>=8,<9' 'ruff<1'
fi

new_section_level_2 "Run unit tests for Python scripts with pytest"
if command -v uv >/dev/null; then
  uv run --with 'pytest>=8,<9' -- python3 -m pytest "$CLI_DIR/tests/python"
else
  source "$venv_name/bin/activate"
  echo 'Running tests...'
  python3 -m pytest "$CLI_DIR/tests/python"
  deactivate
fi

new_section_level_2 "Run linter for Python files"
if command -v uv >/dev/null; then
  uv run --with 'ruff<1' -- ruff check . --exclude "$CLI_DIR/scripts/doc_parser/docopt_ng/"
else
  source "$venv_name/bin/activate"
  echo 'Running linter...'
  ruff check . --exclude "$CLI_DIR/scripts/doc_parser/docopt_ng/"
  deactivate
fi

rm -rf "$venv_name"
echo
echo_done
