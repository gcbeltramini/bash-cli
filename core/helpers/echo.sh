#!/usr/bin/env bash
set -euo pipefail

# Colors
# --------------------------------------------------------------------------------------------------

get_color_code() {
    # Get ANSI escape code for colors.
    #
    # Associative arrays can't be exported in bash. Example:
    #   declare -A COLOR
    #   COLOR=(
    #       ["no_color"]="\x1b[0m"
    #       ["red"]="\x1b[31m"
    #   )
    #   export COLOR
    #
    # If we try to use `COLOR` in another file, it is empty.
    #
    # Usage:
    #   get_color_code <color>
    #
    # Examples:
    #   color_code=$(get_color_code "red")
    #   color_code_no_color=$(get_color_code "no_color")
    #   echo -e "${color_code}Colored text${color_code_no_color}"
    #
    # References:
    # - https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    local -r color=$1
    local -r var_name="COLOR_$(to_uppercase "$color")"
    echo "${!var_name}"
}

echo_color() {
    # Display colored text.
    #
    # Usage:
    #   echo_color <color> <text> [<echo-params>...]
    #
    # Examples:
    #   echo_color "red" "Some error message"
    #   echo_color "blue" "No line skip" -n
    local -r color=$1
    local -r text=$2
    shift 2
    local -r echo_params=("$@")

    local -r color_code=$(get_color_code "$color")
    local -r color_code_no_color=$(get_color_code "no_color")

    echo -e "${echo_params[@]}" "${color_code}${text}${color_code_no_color}"
}

# Logging
# --------------------------------------------------------------------------------------------------

echo_error() {
    # Show error message.
    #
    # Usage:
    #   echo_error <text>
    #
    # Examples:
    #   echo_error "Your command failed."
    local -r text=$1
    echo_color >&2 "red" "ERROR: ${text}"
}

echo_warn() {
    # Show warning message.
    #
    # Usage:
    #   echo_warn <text>
    #
    # Examples:
    #   echo_warn "This is a warning message."
    local -r text=$1
    echo_color >&2 "yellow" "WARNING: ${text}"
}

echo_done() {
    # Show done message.
    #
    # Usage:
    #   echo_done
    echo_color >&2 "green" 'Done!'
}

echo_success() {
  # Show success message.
  #
  # Usage:
  #   echo_success
  echo_color >&2 "green" 'Success!'
}


# Sections
# --------------------------------------------------------------------------------------------------

new_section() {
    # Display section separator.
    #
    # Usage:
    #   new_section <text>
    #
    # Examples:
    #   new_section "Some Title"
    local -r text=$1
    local -r separator_count=100
    local -r separator=$(repeat_char "=" "$separator_count")
    echo -e "\n${separator}\n${text}\n${separator}"
}

new_section_with_color() {
    # Display section separator.
    #
    # Usage:
    #   new_section_with_color <color> <title>
    #
    # Examples:
    #   new_section_with_color "blue" "Some Title"
    local -r color=$1
    local -r title=$2
    local -r section=$(new_section "$title")
    echo_color "$color" "$section"
}


# Debugging
# --------------------------------------------------------------------------------------------------

debug_var_in_file() {
    # Show variables name and value.
    #
    # Useful for debugging CLI commands. Add a call to this function anywhere in the code to see
    # the variable name and value.
    #
    # Usage:
    #   debug_var_in_file filename parent_dir line_number <var_name>...
    #
    # Examples:
    #   ab=42
    #   my_array=(11 22 33)
    #
    #   debug_var_in_file \
    #     "/my/parent/dir/my-filename" \
    #     "/my/parent/dir" \
    #     123 \
    #     'ab' 'cd' 'my_array'
    local -r filename=$1
    local -r parent_dir=$2
    local -r line_number=$3
    shift 3
    local -r var_names=$*
    local -r color="yellow"
    local -r n_chars=100
    # shellcheck disable=SC2001
    local -r bash_source_short=$(echo "${filename}" | sed "s:^${parent_dir}/::")


    echo_color >&2 "$color" "$(surround_text " Debug variables (${bash_source_short}:${line_number}) " $n_chars ">")"
    for var in $var_names; do
        if ! is_set "$var"; then
            echo >&2 "$var=<not set>"
            continue
        fi
        if ! is_array "$var"; then
            echo >&2 "$var='${!var}'"
        else
            local -n array_ref="$var"
            var_array_output="$var="
            for element in "${array_ref[@]}"; do
                var_array_output+="'$element' "
            done
            var_array_output="${var_array_output::-1}" # Remove trailing space
            echo >&2 "$var_array_output"
        fi
    done
    echo_color >&2 "$color" "$(repeat_char "<" $n_chars)"
}

debug_var() {
    # Show variables name and value.
    #
    # Useful for debugging CLI commands. Add a call to this function anywhere in the code to see
    # the variable name and value.
    #
    # Usage:
    #   debug_var <var_name>...
    #
    # Examples:
    #   x=123; debug_var 'x'
    #   x=123; y='qwe'; debug_var 'x' 'y'
    local -r var_names=$*
    debug_var_in_file "${BASH_SOURCE[1]}" "$CLI_PARENT_DIR" "${BASH_LINENO[0]}" "$var_names"
}
