#!/usr/bin/env bash
set -euo pipefail

backup_if_exists() {
  # Create a backup copy of a file or folder if it exists. If it does not exist, do nothing.
  #
  # Usage:
  #   backup_if_exists <name>
  local -r name=$1
  if [[ -e $name ]]; then
    local -r timestamp=$(date +"%Y%m%d%H%M%S")
    local -r backup_path="${name}.${timestamp}.bkp"

    cp -r "$name" "$backup_path"

    echo >&2 "'$name' already exists. Backup created: '$backup_path'"
  fi
}

# Files
# ------------------------------------------------------------------------------

find_relevant_files() {
  # List relevant files.
  #
  # Usage:
  #   find_relevant_files [<path> <find-args>]
  #
  # Options:
  #   <path>       Path to the directory to search for files [default: .]
  #   <find-args>  Additional arguments to pass to the find command
  local -r path_name=${1:-.}
  shift 1 || true
  local find_args=("$@")

  find "$path_name" \
    -type f \
    -not -name '.DS_Store' \
    -not -name '*.exe' \
    -not -name '*.pyc' \
    -not -name '*.pyo' \
    -not -name '*.egg' \
    -not -name '*.egg-info' \
    -not -path '*/*.egg-info/*' \
    -not -name '*.whl' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.mypy_cache/*' \
    -not -path '*/.pytest_cache/*' \
    -not -path '*/.ruff_cache/*' \
    -not -path '*/.venv/*' \
    -not -path '*/venv/*' \
    -not -path '*/.venv_*/*' \
    -not -path '*/venv_*/*' \
    -not -path '*/.ipynb_checkpoints/*' \
    -not -path '*/node_modules/*' \
    -not -name '*.gz' \
    -not -name '*.tar' \
    -not -name '*.zip' \
    -not -name '*.jpg' \
    -not -name '*.png' \
    -not -name '*.tfstate' \
    -not -name '*.tfstate.backup' \
    -not -name '*.coverage' \
    -not -path '*/.git/*' \
    -not -name '.gitkeep' \
    -not -path '*/.idea/*' \
    -not -path '*/.terraform/*' \
    "${find_args[@]}" #\
  # Maybe ignore binary files with:
  # ! -exec file --mime {} + |
  # grep -v ': binary' |
  # awk -F: '{print $1}'
}

files_not_ending_with_newline() {
  # List files that do not end with a newline.
  #
  # Usage:
  #   files_not_ending_with_newline <files>
  #
  # References:
  # - Based on: https://stackoverflow.com/a/25686825/7649076
  # - "Why should text files end with a newline?":
  #   https://stackoverflow.com/questions/729692/why-should-text-files-end-with-a-newline
  local -r files=$1
  while IFS= read -r file; do
    if [[ -n "$(tail -c 1 "$file")" ]]; then
      echo "$file"
    fi
  done < <(printf '%s\n' "$files")
}

has_exactly_one_line_at_the_end() {
  # Check if file has exactly one empty line at the end.
  #
  # Usage:
  #   has_exactly_one_line_at_the_end <file>
  local -r file=$1

  if [[ -n "$(tail -c 1 "$file")" ]]; then
    # No empty line at the end
    return 1
  elif tail -n 1 "$file" | grep -q '^ *$'; then
    # More than one empty line at the end
    return 2
  else
    return 0
  fi
}

# Directories
# ------------------------------------------------------------------------------

find_dirs_with_only_hidden_files() {
  # Find directories that contain only hidden files and directories.
  #
  # Usage:
  #   find_dirs_with_only_hidden_files <path>
  local -r path=$1

  find "$path" -type d -exec bash -c '
      files=$(ls -A "$1" 2>/dev/null)
      if [[ -n "$files" ]]; then
        hidden_files=$(ls -A "$1" 2>/dev/null | grep "^\.")
        if [[ "$files" == "$hidden_files" ]]; then
          echo "$1"
        fi
      fi
    ' _ {} \;
}
