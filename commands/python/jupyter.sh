#!/usr/bin/env bash
set -euo pipefail

##? Deal with Jupyter notebooks.
##?
##? Usage:
##?   python jupyter list [<path> --maxdepth=DEPTH]
##?   python jupyter clear [<path> --maxdepth=DEPTH --force]
##?   python jupyter clean-metadata <file> [<output-file>]
##?
##? Options:
##?   list              List all Jupyter notebooks
##?   clear             Find all Jupyter notebooks and clear their outputs using 'nbconvert'.
##?   clean-metadata    Clean cell-level metadata from Jupyter notebook files
##?   <path>            Path to use [default: "."]
##?   --maxdepth=DEPTH  Maximum depth to search for Jupyter notebooks. The default is unlimited.
##?   --force           Skip the confirmation prompt when clearing notebook outputs

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare clean_metadata clear file force list maxdepth output_file path

path="${path:-.}" # "." looks better in the terminal than "$PWD"

if [[ -n "$maxdepth" ]]; then
  maxdepth_arg=("-maxdepth" "$maxdepth")
else
  maxdepth_arg=()
fi

if $list; then
  echo >&2 "Listing all Jupyter notebooks..."
  find "$path" \
    "${maxdepth_arg[@]}" \
    -type f \
    -name "*.ipynb" \
    ! -path "*/.ipynb_checkpoints/*" |
    sort
elif $clear; then
  if ! $force; then
    confirm "The outputs of all Jupyter notebooks in '$path' and subfolders will be cleared. Do you want to continue?"
  fi
  # There could be Jupyter notebooks inside venvs, and we will remove their outputs as well.
  find "$path" \
    "${maxdepth_arg[@]}" \
    -type f \
    -name "*.ipynb" \
    ! -path "*/.ipynb_checkpoints/*" \
    -print0 |
    while IFS= read -r -d '' notebook; do
      echo "Clearing output for '$notebook'..."
      jupyter nbconvert --clear-output --inplace "$notebook"
    done
elif $clean_metadata; then
  ipynb_cleanmetadata "$file" "${output_file:-$file}"
  echo_gray "Metadata cleaned from '$file' (output: '${output_file:-$file}')"
fi

echo_done
