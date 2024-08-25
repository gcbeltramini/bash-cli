#!/usr/bin/env bash
set -euo pipefail

is_mac() {
    # Check if on a Mac computer.
    #
    # Usage:
    #   is_mac
    #
    # Examples:
    #   is_mac && echo "Mac computer"
    [[ $(uname) == "Darwin" ]]
}

get_dir_name() {
    # Get the directory name of a file or folder. If the path doesn't exist, return an empty string.
    #
    # Usage:
    #   get_dir_name <path>
    local -r path=$1
    cd -- "$(dirname -- "$path")" &>/dev/null && pwd
}
