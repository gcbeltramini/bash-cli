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
