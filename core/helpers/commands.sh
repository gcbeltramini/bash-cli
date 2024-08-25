#!/usr/bin/env bash
set -euo pipefail

command_exists() {
    # Check if a command exists.
    #
    # Usage:
    #   command_exists <cmd>
    #
    # Examples:
    #   if command_exists ls; then echo "Command 'ls' exists."; fi
    #   if command_exists foo; then echo "Command 'foo' does not exist."; fi
    local -r cmd=$1
    command -v "$cmd" >/dev/null
}
