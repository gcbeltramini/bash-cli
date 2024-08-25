#!/usr/bin/env bash
set -euo pipefail

# Run by 'mycli version'

echo
echo "Last modification in mycli"
echo "--------------------------"
git -C "$CLI_DIR" show --summary
