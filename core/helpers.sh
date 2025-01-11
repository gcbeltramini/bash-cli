#!/usr/bin/env bash
set -euo pipefail

# Script used to `source` all helper files to enable all functions and constants in the commands.
# This file should be used in the commands like this:
#   source "${CLI_DIR}/core/helpers.sh"

for helper in "${CLI_DIR}/core/helpers/"*".sh"; do
    if [[ -f "$helper" ]]; then
        # shellcheck disable=SC1090
        source "$helper"
    fi
done
