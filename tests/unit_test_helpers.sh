#!/usr/bin/env bash
set -euo pipefail

# Sections
# --------------------------------------------------------------------------------------------------

new_section_level_2() {
    # Create section separator.
    #
    # Usage:
    #   new_section_level_2 <text>
    local -r text=$1
    echo
    echo "--------------------------------------------------------------------------------"
    echo "$text"
}

# Messages
# --------------------------------------------------------------------------------------------------

echo_error() {
    # Show error message.
    #
    # Usage:
    #   echo_error <message>
    local -r message=$1
    echo >&2 -e "\033[31m[ERROR]\033[0m ${message}"
}

get_test_running_message() {
    # Get message to show that the test is running.
    #
    # Usage:
    #   get_test_running_message <test_file> [<path_to_remove>]
    local -r test_file=$1
    local -r path_to_remove=${2:-}
    echo "Running tests from '$(clean_path_name "$test_file" "$path_to_remove")'"
}

# Files
# --------------------------------------------------------------------------------------------------

clean_path_name() {
    # Remove path from path name to make it shorter.
    #
    # Usage:
    #   clean_path_name <path> [<to_remove>]
    local -r path_name=$1
    local -r to_remove=${2:-}
    if [[ -z "$to_remove" ]]; then
        echo "$path_name"
    else
        echo "$path_name" | sed -E "s:^${to_remove}/*::"
    fi
}

get_all_shell_files() {
    # Get all shell files in a folder.
    #
    # Usage:
    #   get_all_shell_files [<path>]
    local -r path_name=${1:-$CLI_DIR}
    find "$path_name" \
        -type f \
        -not -path '*/.git/*' \
        \( -name "*.sh" -o -name "*.bash" \) | {
        echo "${path_name}/mycli"
        cat
    }
}

get_all_files() {
    # Get all files in a folder.
    #
    # Usage:
    #   get_all_files [<path>]
    local -r path_name=${1:-$CLI_DIR}
    find "$path_name" \
        -type f \
        -not -path '*/.git/*' \
        -not -path '*/.pytest_cache/*' \
        -not -name '*.pyc' \
        -not -name '.DS_Store'
}

get_all_command_files() {
    # Get all command files in a folder.
    #
    # Usage:
    #   get_all_command_files [<path>]
    local -r path_name=${1:-$CLI_DIR}
    find "$path_name/commands" -maxdepth 2 -mindepth 2 -type f -name '*.sh'
}

get_all_helper_files() {
    # Get all helper files in a folder (excluding the file "constants.sh").
    #
    # Usage:
    #   get_all_helper_files [<path>]
    local -r path_name=${1:-$CLI_DIR}
    find "$path_name/core/helpers" \
        -maxdepth 1 \
        -type f \
        -name '*.sh' \
        -not -name 'constants.sh'
}

get_all_test_helper_files() {
    # Get all test helper files in a folder.
    #
    # Usage:
    #   get_all_test_helper_files [<path>]
    local -r tests_dir=${1:-$TESTS_DIR}
    find "${tests_dir}/core/helpers" -type f -name 'test_*.sh'
}

get_all_test_files() {
    # Get all test files in a folder.
    #
    # Usage:
    #   get_all_test_files [<path>]
    local -r tests_dir=${1:-$TESTS_DIR}
    find "$tests_dir" -type f \( -name 'test_*.sh' -o -name 'test_*.zsh' \)
}

# Utils
# --------------------------------------------------------------------------------------------------

check_if_error() {
    # Check if there are files with error. If there are, display error message and exit with error;
    # otherwise, display success message.
    #
    # Usage:
    #   check_if_error <invalid_files> [<error_msg>]
    local -r invalid_files=$(echo -e "$1" | sed '/^[[:space:]]*$/d')
    local -r error_msg=${2:-"Invalid files:"}
    local -r cli_dir=$CLI_DIR

    if [[ -n $invalid_files ]]; then
        echo_error "$error_msg"
        while IFS= read -r line; do
            if [ -f "$line" ]; then
                file_path=$(realpath "$line")
            else
                file_path="$line"
            fi
            clean_path_name "$file_path" "$cli_dir" >&2
        done <<<"$invalid_files"
        exit 1
    else
        echo 'OK!'
    fi
}

remove_from_list() {
    # COPIED FROM core/helpers/string.sh TO AVOID SOURCING EXTERNAL FILES.
    #
    # Remove lines that match a list of regex.
    #
    # Usage:
    #   remove_from_list <list> <list_regex>
    local -r list=$1
    local -r list_regex=$2
    if [[ -z "$list_regex" ]]; then
        echo -e "$list"
    else
        echo -e "$list" | grep -vf <(echo -e "$list_regex") || :
    fi
}

# Tests
# --------------------------------------------------------------------------------------------------

has_invalid_shebang() {
    # Check if file contains an invalid shebang in the first line.
    #
    # Usage:
    #   has_invalid_shebang <desired_shebang> <file>
    #
    # Examples:
    #   if has_invalid_shebang "#!/usr/bin/env " "my-file.py"; then echo "invalid"; fi
    local -r desired_shebang=$1
    local -r file=$2

    local -r first_line=$(head -n 1 "$file")
    [[ "$first_line" != "$desired_shebang"* ]]
}

has_invalid_set() {
    # Check if file contains an invalid set command in the first uncommented, non-empty line.
    #
    # Usage:
    #   has_invalid_set <desired_set> <file>
    #
    # Examples:
    #   has_invalid_set "set -euo pipefail" "my-file.sh"
    local -r desired_set=$1
    local -r file=$2

    ! grep -m1 -v -e "^#" -e "^ *$" "$file" | grep -q "^${desired_set}$"
}

has_shellcheck_all_disabled() {
    # Check if all instances of shellcheck errors are disabled in a file.
    #
    # To ignore all instances in a file, the directive must be on the first line after the shebang.
    # Comments and whitespace are ignored.
    #
    # Usage:
    #   has_shellcheck_all_disabled <file>
    #
    # References:
    # - https://www.shellcheck.net/wiki/Ignore ("Ignoring all instances in a file")
    local -r file=$1

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*'#'[[:space:]]*'shellcheck'[[:space:]]+'disable=' ]]; then
            return 0
        fi

        if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]]; then
            # skip empty lines, comments and the shebang (start with '#')
            continue
        fi

        # Reached a line that is not empty, is not a comment, is not the shebang, and does not disable shellcheck
        return 1
    done <"$file"
}

find_not_executable() {
    # Check if specific files are executable.
    #
    # Usage:
    #   find_not_executable <parent_dir>
    local -r parent_dir=$1
    find \
        "${parent_dir}/commands" "${parent_dir}/tests" \
        -type f \
        -name '*.sh' \
        -not -exec test -x {} \; \
        -print
}

find_forbidden_cmd_names() {
    # Check if there are commands with forbidden names:
    # - "update" and "version" can't be folder names
    # - files can't have spaces in their names
    #
    # Usage:
    #   find_forbidden_cmd_names [<path>]
    local -r path_name=${1:-$CLI_DIR}
    find "$path_name/commands" -type d \( -name 'update' -o -name 'version' \) -o -type f -name '* *.sh'
}

has_exactly_one_line_at_the_end() {
    # COPIED FROM core/helpers/files.sh TO AVOID SOURCING EXTERNAL FILES.
    #
    # Check if file has exactly one empty line at the end.
    #
    # Usage:
    #   has_exactly_one_line_at_the_end <file>
    local -r file=$1

    if [[ -n "$(tail -c 1 "$file")" ]]; then
        # No empty line at the end
        return 1
    elif tail -n 1 "$file" | grep -q '^ *$'; then
        # More than one empty line at the end
        return 2
    else
        return 0
    fi
}

get_variable_def_or_fn_call() {
    # Get lines with variable definition or function call in file.
    #
    # Usage:
    #   get_variable_def_or_fn_call <file>
    local -r file=$1

    local -r allowed_beginning_line=(
        "#"
        "set "
        "$"
        "[[:space:]]"
        ".*\(\) \{"
        "}"
        "EOF"
    )

    # Join the elements using '|'
    IFS='|' allowed_beginning_line_regex="${allowed_beginning_line[*]}"

    grep -vE "^($allowed_beginning_line_regex)" "$file" || :
}
