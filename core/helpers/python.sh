#!/usr/bin/env bash
set -euo pipefail

run_python_script() {
  # Run a Python script with the given arguments.
  #
  # The Python version and dependencies are defined by the script metadata [1,2,3].
  #
  # Usage:
  #   run_python_script <python_script> [<script_args>...]
  #
  # References:
  # [1] https://packaging.python.org/en/latest/specifications/inline-script-metadata/
  # [2] https://peps.python.org/pep-0723/
  # [3] https://docs.astral.sh/uv/guides/scripts/#creating-a-python-script
  #
  # Examples:
  #   run_python_script "my/python/script.py" "foo" "--bar=42" "--some-flag"
  local -r python_script=$1
  shift 1
  local -r script_args=("$@")

  uv run "$python_script" "${script_args[@]}"
}

ipynb_cleanmetadata() {
  # Clean cell-level metadata from Jupyter notebook files.
  #
  # Usage:
  #   ipynb_cleanmetadata <file> [<output-file>]
  local -r file="$1"
  local -r output_file="${2:-$file}"

  # Use a temporary file to avoid truncating the output on jq failure.
  local tmp_file
  tmp_file="$(mktemp "${output_file}.XXXXXX")"

  if jq --indent 1 '.cells[].metadata = {}' "$file" >"$tmp_file"; then
    mv "$tmp_file" "$output_file"
  else
    rm -f "$tmp_file"
    return 1
  fi
}
