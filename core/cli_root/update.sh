#!/usr/bin/env bash
set -euo pipefail

# Run by 'mycli update'

echo
echo "Updating mycli"
echo "--------------"
git -C "$CLI_DIR" pull origin main
bash "${CLI_DIR}/scripts/generate_command_index.sh"
