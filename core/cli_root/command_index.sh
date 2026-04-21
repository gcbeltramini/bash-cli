#!/usr/bin/env bash
set -euo pipefail

mycli_command_index_path() {
  # Get the command index path from the commands directory path.
  #
  # Usage:
  #   mycli_command_index_path <commands_dir>
  local -r commands_dir=$1
  printf '%s/core/cli_root/command_index.tsv\n' "$(dirname "$commands_dir")"
}

mycli_command_index_exists() {
  # Check whether the generated command index exists.
  #
  # Usage:
  #   mycli_command_index_exists <commands_dir>
  local -r commands_dir=$1
  [[ -f "$(mycli_command_index_path "$commands_dir")" ]]
}

mycli_extract_command_description() {
  # Extract the command description from the command README file.
  #
  # Usage:
  #   mycli_extract_command_description <readme_path>
  local -r readme_path=$1
  local description

  if [[ ! -s "$readme_path" ]]; then
    echo '<no description>'
    return 0
  fi

  description=$(awk '!/^[[:space:]]*#/ && !/^[[:space:]]*$/ { print; exit }' "$readme_path")
  if [[ -n $description ]]; then
    echo "$description"
  else
    echo '<no description>'
  fi
}

mycli_extract_subcommand_description() {
  # Extract the short description from the subcommand help header.
  #
  # Usage:
  #   mycli_extract_subcommand_description <command_file>
  local -r command_file=$1
  awk '/^##\?/ { sub(/^##\? */, "", $0); print; exit }' "$command_file"
}

mycli_generate_command_index() {
  # Generate the command index file.
  #
  # Usage:
  #   mycli_generate_command_index <cli_dir>
  local -r cli_dir=$1
  local -r commands_dir="${cli_dir}/commands"
  local -r output_path="${cli_dir}/core/cli_root/command_index.tsv"
  local command_dir command command_description command_file relative_path subcommand subcommand_description

  {
    for command_dir in "${commands_dir}"/*; do
      [[ -d "$command_dir" ]] || continue

      command=$(basename "$command_dir")
      command_description=$(mycli_extract_command_description "${command_dir}/README.md")

      for command_file in "${command_dir}"/*.sh; do
        [[ -f "$command_file" ]] || continue

        subcommand=$(basename "$command_file" ".sh")
        subcommand_description=$(mycli_extract_subcommand_description "$command_file")
        relative_path=${command_file#"${cli_dir}/"}

        printf '%s\t%s\t%s\t%s\t%s\n' \
          "$command" \
          "$subcommand" \
          "$relative_path" \
          "${subcommand_description//$'\t'/ }" \
          "${command_description//$'\t'/ }"
      done
    done

    printf '%s\t%s\t%s\t%s\t%s\n' 'update' '' 'core/cli_root/update.sh' 'Update the CLI.' 'Update mycli'
    printf '%s\t%s\t%s\t%s\t%s\n' 'version' '' 'core/cli_root/version.sh' 'Show the CLI version.' 'Show mycli version'
  } | LC_ALL=C sort >"$output_path"
}

mycli_find_command_paths_from_scan() {
  # Find command paths by scanning the commands directory.
  #
  # Usage:
  #   mycli_find_command_paths_from_scan <commands_dir> <cmd1> <cmd2>
  local -r commands_dir=$1
  local -r cmd1=$2
  local -r cmd2=$3

  find "$commands_dir" \
    -type f \
    -maxdepth 2 \
    -path "${commands_dir}/${cmd1}*/*" \
    -name "${cmd2}*.sh"
}

mycli_find_command_paths() {
  # Find command paths using the generated index when available.
  #
  # Usage:
  #   mycli_find_command_paths <commands_dir> <cmd1> <cmd2>
  local -r commands_dir=$1
  local -r cmd1=$2
  local -r cmd2=$3
  local -r cli_dir=$(dirname "$commands_dir")
  local command subcommand relative_path

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_find_command_paths_from_scan "$commands_dir" "$cmd1" "$cmd2"
    return 0
  fi

  while IFS=$'\t' read -r command subcommand relative_path _ _; do
    [[ $command == ${cmd1}* ]] || continue
    [[ $subcommand == ${cmd2}* ]] || continue
    printf '%s/%s\n' "$cli_dir" "$relative_path"
  done <"$(mycli_command_index_path "$commands_dir")"
}

mycli_list_commands_for_help_from_scan() {
  # List all commands and subcommands by scanning the commands directory.
  #
  # Usage:
  #   mycli_list_commands_for_help_from_scan <commands_dir>
  local -r commands_dir=$1
  local cmd_subcommand description

  find "$commands_dir" -mindepth 2 -maxdepth 2 -type f -name '*.sh' | while read -r command_file; do
    cmd_subcommand=$(echo "$command_file" | awk -F/ '{print $(NF-1) " " $NF}' | sed 's/\.sh$//')
    description=$(grep -m 1 '^##?' "$command_file" | sed 's/^##? *//')
    echo -e "$cmd_subcommand\t-- $description"
  done
  echo -e 'update\t-- Update the CLI.'
  echo -e 'version\t-- Show the CLI version.'
}

mycli_list_commands_for_help() {
  # List all commands and subcommands with descriptions for the CLI help.
  #
  # Usage:
  #   mycli_list_commands_for_help <commands_dir>
  local -r commands_dir=$1
  local command subcommand subcommand_description

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_list_commands_for_help_from_scan "$commands_dir"
    return 0
  fi

  while IFS=$'\t' read -r command subcommand _ subcommand_description _; do
    if [[ -n $subcommand ]]; then
      printf '%s %s\t-- %s\n' "$command" "$subcommand" "$subcommand_description"
    else
      printf '%s\t-- %s\n' "$command" "$subcommand_description"
    fi
  done <"$(mycli_command_index_path "$commands_dir")"
}

mycli_list_subcommands_for_help_from_scan() {
  # List matching subcommands by scanning the commands directory.
  #
  # Usage:
  #   mycli_list_subcommands_for_help_from_scan <commands_dir> <command>
  local -r commands_dir=$1
  local -r command=$2
  local subcommand description

  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name '*.sh' | while read -r command_file; do
    subcommand=$(echo "$command_file" | awk -F/ '{print $NF}' | sed 's/\.sh$//')
    description=$(grep -m 1 '^##?' "$command_file" | sed 's/^##? *//')
    echo -e "$subcommand\t-- $description"
  done
}

mycli_list_subcommands_for_help() {
  # List matching subcommands with descriptions for the CLI help.
  #
  # Usage:
  #   mycli_list_subcommands_for_help <commands_dir> <command>
  local -r commands_dir=$1
  local -r command_prefix=$2
  local command subcommand subcommand_description

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_list_subcommands_for_help_from_scan "$commands_dir" "$command_prefix"
    return 0
  fi

  while IFS=$'\t' read -r command subcommand _ subcommand_description _; do
    [[ $command == ${command_prefix}* ]] || continue
    [[ -n $subcommand ]] || continue
    printf '%s\t-- %s\n' "$subcommand" "$subcommand_description"
  done <"$(mycli_command_index_path "$commands_dir")"
}

mycli_list_commands_from_scan() {
  # List top-level commands by scanning the commands directory.
  #
  # Usage:
  #   mycli_list_commands_from_scan <commands_dir>
  local -r commands_dir=$1

  find "$commands_dir" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -exec basename {} \;
  echo 'update'
  echo 'version'
}

mycli_list_commands() {
  # List top-level commands.
  #
  # Usage:
  #   mycli_list_commands <commands_dir>
  local -r commands_dir=$1
  local command previous_command=''

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_list_commands_from_scan "$commands_dir"
    return 0
  fi

  while IFS=$'\t' read -r command _ _ _ _; do
    if [[ $command != "$previous_command" ]]; then
      echo "$command"
      previous_command=$command
    fi
  done <"$(mycli_command_index_path "$commands_dir")"
}

mycli_list_subcommands_from_scan() {
  # List subcommands by scanning the commands directory.
  #
  # Usage:
  #   mycli_list_subcommands_from_scan <commands_dir> <command>
  local -r commands_dir=$1
  local -r command=$2

  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name '*.sh' \
    -exec basename {} \; |
    sed 's/\.sh$//'
}

mycli_list_subcommands() {
  # List subcommands for a command prefix.
  #
  # Usage:
  #   mycli_list_subcommands <commands_dir> <command>
  local -r commands_dir=$1
  local -r command_prefix=$2
  local command subcommand

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_list_subcommands_from_scan "$commands_dir" "$command_prefix"
    return 0
  fi

  while IFS=$'\t' read -r command subcommand _ _ _; do
    [[ $command == ${command_prefix}* ]] || continue
    [[ -n $subcommand ]] || continue
    echo "$subcommand"
  done <"$(mycli_command_index_path "$commands_dir")"
}

mycli_list_commands_and_description_from_scan() {
  # List top-level commands and descriptions by scanning the commands directory.
  #
  # Usage:
  #   mycli_list_commands_and_description_from_scan <commands_dir>
  local -r commands_dir=$1
  local description

  find "$commands_dir" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -exec basename {} \; | while read -r command; do
    if [[ -s "$commands_dir/$command/README.md" ]]; then
      description=$(grep -m 1 -vE '^#|^[[:space:]]*$' "$commands_dir/$command/README.md")
    else
      description='<no description>'
    fi
    echo "$command:$description"
  done
  echo 'update:Update mycli'
  echo 'version:Show mycli version'
}

mycli_list_commands_and_description() {
  # List top-level commands and descriptions.
  #
  # Usage:
  #   mycli_list_commands_and_description <commands_dir>
  local -r commands_dir=$1
  local command command_description previous_command=''

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_list_commands_and_description_from_scan "$commands_dir"
    return 0
  fi

  while IFS=$'\t' read -r command _ _ _ command_description; do
    if [[ $command != "$previous_command" ]]; then
      echo "$command:$command_description"
      previous_command=$command
    fi
  done <"$(mycli_command_index_path "$commands_dir")"
}

mycli_list_subcommands_and_description_from_scan() {
  # List subcommands and descriptions by scanning the commands directory.
  #
  # Usage:
  #   mycli_list_subcommands_and_description_from_scan <commands_dir> <command>
  local -r commands_dir=$1
  local -r command=$2
  local filename description

  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name '*.sh' | while read -r file; do
    filename=$(basename "$file" '.sh')
    description=$(grep -m 1 '^##?' "$file" | sed 's/^##? *//')
    echo "$filename:$description"
  done
}

mycli_list_subcommands_and_description() {
  # List subcommands and descriptions for a command prefix.
  #
  # Usage:
  #   mycli_list_subcommands_and_description <commands_dir> <command>
  local -r commands_dir=$1
  local -r command_prefix=$2
  local command subcommand subcommand_description

  if ! mycli_command_index_exists "$commands_dir"; then
    mycli_list_subcommands_and_description_from_scan "$commands_dir" "$command_prefix"
    return 0
  fi

  while IFS=$'\t' read -r command subcommand _ subcommand_description _; do
    [[ $command == ${command_prefix}* ]] || continue
    [[ -n $subcommand ]] || continue
    echo "$subcommand:$subcommand_description"
  done <"$(mycli_command_index_path "$commands_dir")"
}
