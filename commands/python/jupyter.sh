#!/usr/bin/env bash
set -euo pipefail

##? Clean cell metadata from Jupyter notebook files.
##?
##? Usage:
##?   python jupyter clean-metadata <file> [<output-file>]
##?
##? Options:
##?   clean-metadata  Clean cell-level metadata from Jupyter notebook files
##?
##? Examples:
##?   python jupyter clean-metadata my-notebook.ipynb

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare clean_metadata file output_file

if $clean_metadata; then
  ipynb_cleanmetadata "$file" "${output_file:-$file}"
  echo_progress "Metadata cleaned from '$file' (output: '${output_file:-$file}')"
  echo_done
fi
