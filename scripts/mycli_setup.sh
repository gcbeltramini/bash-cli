#!/usr/bin/env bash
set -euo pipefail

# Script used to set up the CLI. No external function is used. It is idempotent.

# Functions
# --------------------------------------------------------------------------------------------------

echo_color() {
    local -r color=$1
    local -r text=$2
    local -r no_color='\x1b[0m'
    echo -e "${color}${text}${no_color}"
}

show_section() {
    local -r section=$1
    local -r separator='----------------------------------------------------------------------------------------------------'
    echo
    echo "$separator"
    echo "$section"
    echo "$separator"
}

show_done() {
    echo_color "\x1b[32m" 'Done!'
}

get_cli_dir() {
    # Get the directory of the CLI repository. It is assumed that this script is in the 'scripts' directory.
    local -r curr_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    dirname "$curr_dir"
}

make_executable() {
    local -r parent_dir=$1
    find \
        "${parent_dir}/commands" "${parent_dir}/tests" \
        -type f \
        -name '*.sh' \
        -exec chmod +x {} \;
}

# Install Homebrew
# --------------------------------------------------------------------------------------------------

if ! command -v brew >/dev/null; then
    show_section "Install Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    show_done
fi

# Install commands with Homebrew
# --------------------------------------------------------------------------------------------------

show_section "Install the required commands"
brew install bash coreutils findutils gawk gnu-sed grep jq shellcheck sponge wget
show_done

# Edit the PATH variable
# --------------------------------------------------------------------------------------------------

show_section "Add the CLI to the 'PATH' variable"
shell_files=(
    "${HOME}/.bash_profile"
    "${HOME}/.zshrc"
)
start_pattern="# >>> mycli >>>"
end_pattern="# <<< mycli <<<"
cli_dir=$(get_cli_dir)
parent_dir=$(dirname "$cli_dir")
for shell_file in "${shell_files[@]}"; do
    if [[ -f $shell_file ]]; then
        timestamp=$(date +"%Y%m%d%H%M%S")
        backup_path="${shell_file}.${timestamp}.bkp"
        cp "$shell_file" "$backup_path"
        echo "'$shell_file' already exists. Backup created: '$backup_path'"
    fi

    echo -n "Removing multiple empty lines and the section between '$start_pattern' and '$end_pattern' in file '$shell_file'... "
    sed -e "/^[[:space:]]*$/N;/^\n[[:space:]]*$/D" -e "/^[[:space:]]*$start_pattern/,/$end_pattern/d" "$shell_file" | sponge "$shell_file"
    show_done

    echo -n "Appending the CLI configuration to '$shell_file'... "
    # shellcheck disable=SC2016
    # You can add here custom functions, aliases, environment variables.
    to_add="

$start_pattern
MYCLI_HOME=\"${cli_dir}\""'
[ -f "$MYCLI_HOME/core/cli_root/autocomplete.sh" ] && source "$MYCLI_HOME/core/cli_root/autocomplete.sh"
export PATH="${MYCLI_HOME}:${PATH}"
'"$end_pattern"
    echo "$to_add" >>"$shell_file"
    show_done
done

# Make scripts executable
# --------------------------------------------------------------------------------------------------

show_section "Make the required scripts executable"
make_executable "$cli_dir"
show_done

# Last message
# --------------------------------------------------------------------------------------------------

show_section "Final message"
echo "'mycli' is installed! Open a new terminal and run:"
echo "  mycli hello world"
