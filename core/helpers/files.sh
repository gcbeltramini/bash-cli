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

check_if_file_exists() {
  # Check if a file exists.
  #
  # Usage:
  #   check_if_file_exists <file>
  local -r file=$1
  if [[ ! -e $file ]]; then
    exit_with_error "File '$file' not found."
  fi
}

file_to_base64() {
  # Convert a file to base64.
  #
  # Usage:
  #   file_to_base64 <file>
  local -r file=$1
  base64 -w 0 "$file" # '-w' is a GNU-specific flag, i.e., only works with 'gbase64'
}

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

yaml2json() {
  # Convert YAML to JSON.
  #
  # Usage:
  #   yaml2json <file>
  local -r file=$1

  if ! python3 -c 'import yaml' &>/dev/null; then
    exit_with_error "PyYAML is not installed (Python package \"yaml\"); cannot convert '$file' to JSON."
  fi

  local -r code='import sys, yaml, json; json.dump(yaml.safe_load(sys.stdin), sys.stdout, indent=2)'
  python3 -c "$code" <"$file"
  # ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' "$file"
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

find_empty_dirs() {
  # Find empty directories.
  #
  # Usage:
  #   find_empty_dirs [<path>]
  local -r path=${1:-.}

  find "$path" \
    -type d \
    -empty \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*'
}

delete_empty_dirs() {
  # Delete empty directories.
  #
  # Usage:
  #   delete_empty_dirs [<path>]
  local -r path=${1:-.}

  find_empty_dirs "$path" | xargs -r rm -rf
}

# List
# ------------------------------------------------------------------------------

ls_files() {
  # List files in a directory, ignoring directories.
  #
  # Usage:
  #   ls_files [<path>]
  local -r path_name=${1:-.}
  # shellcheck disable=SC2010
  ls -l "$path_name" | grep -v '^d' | sed 1d
}

ls_dirs() {
  # List directories in a directory, ignoring files.
  #
  # Usage:
  #   ls_dirs [<path>]
  local -r path_name=${1:-.}
  # shellcheck disable=SC2010
  ls -l "$path_name" | grep --color=never '^d' || true
}

ll_full() {
  # `ls` with some information and header.
  #
  # Usage:
  #   ll_full [<path>]
  local -r path_name=${1:-.}

  # shellcheck disable=SC2012
  ls -lAhF --time-style='+%Y-%m-%d %H:%M:%S %z' "$path_name" | # in macOS, '--time-style=' is equivalent to '-D'
    sed 1d |
    awk -v OFS='\t' 'BEGIN {print "PERMISSION\tLINKS\tOWNER\tGROUP\tSIZE\tDATE\tHH:MM:SS\tTZ\tNAME\n";}
                      {s=""; for (i=9; i<=NF; i++) s=s$i" "; print $1,$2,$3,$4,$5,$6,$7,$8,s;}' |
    column -t -s $'\t'
}

ll_part() {
  # Same as `ll_full` but with less columns.
  #
  # Usage:
  #   ll_part [<path>]
  local -r path_name=${1:-.}

  # shellcheck disable=SC2012
  ls -lAhF --time-style='+%Y-%m-%d %H:%M:%S %z' "$path_name" | # in macOS, '--time-style=' is equivalent to '-D'
    sed 1d |
    awk -v OFS='\t' 'BEGIN {print "SIZE\tDATE\tHH:MM:SS\tTZ\tNAME\n";}
                      {s=""; for (i=9; i<=NF; i++) s=s$i" "; print $5,$6,$7,$8,s;}' |
    column -t -s $'\t'
}

ls_file_time() {
  # Display file creation, modification, change and access times.
  #
  # Usage:
  #   ls_file_time [<path>]
  local -r path_name=${1:-.}

  if [ -z "$(ls -A "$path_name")" ]; then # directory is empty
    # echo -e "CREATED\tMODIFIED\tSTATUS_CHANGED\tACCESSED\tSIZE\tNAME" # print only the header
    echo_warn "Directory '$path_name' is empty."
    return 0
  fi

  (printf 'CREATED\tMODIFIED\tSTATUS_CHANGED\tACCESSED\tSIZE\tNAME\n' &&
    stat --printf '%w\t%y\t%z\t%x\t%s\t%n\n' "$path_name"/*) | # in macOS, use `stat -f '%SB%t%Sm%t%Sc%t%Sa%t%z%t%N' -t '%Y-%m-%d %H:%M:%S'`
    column -t -s $'\t'
}

count_ext() {
  # Count the number of files with each extension; hidden files are ignored.
  #
  # Usage:
  #   count_ext [<path> <max-depth>]
  local -r path_name=${1:-.}
  local -r max_depth=${2:-1}

  find "$path_name" -maxdepth "$max_depth" -type f -not -path '*/\.*' |
    sed -n '/\./s/.*\.//p' | # Extract the extension (characters after the last dot)
    sort | uniq -c |
    awk 'BEGIN {print "EXTENSION\tCOUNT";} {print $2"\t"$1}' |
    column -t -s $'\t'
}
