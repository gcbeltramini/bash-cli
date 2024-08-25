#!/usr/bin/env bash
set -euo pipefail

# Run by 'mycli update'

echo
echo "Updating mycli"
echo "--------------"
git -C "$CLI_DIR" pull origin main
