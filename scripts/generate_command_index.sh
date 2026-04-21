#!/usr/bin/env bash
set -euo pipefail

CLI_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)

source "${CLI_DIR}/core/cli_root/command_index.sh"

mycli_generate_command_index "$CLI_DIR"
