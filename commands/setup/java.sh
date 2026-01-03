#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Set up Java on your computer.
##?
##? This script installs 'jenv' and Azul Zulu Java, which works in architectures x86_64 and arm64.
##?
##? Usage:
##?   setup java [--version=VERSION]
##?
##? Options:
##?   --version=VERSION  Java version (8, 11, 17, 21) [default: 21]
##?
##? References:
##? - https://www.oracle.com/java/technologies/java-se-support-roadmap.html
##? - https://www.azul.com/downloads/?package=jdk#zulu
##?
##? Examples:
##?   setup java
##?   setup java --version=17

parse_help "$@"
declare version

color='blue'

new_section_with_color "$color" "Install 'jenv' and Azul Zulu version $version"
brew install jenv zulu@"$version"
echo_done

new_section_with_color "$color" "Edit '$HOME/.zshrc' to set up 'jenv'"
# shellcheck disable=SC2016
if grep -q '^eval "$(jenv init -)"' "$HOME/.zshrc"; then
  echo "'jenv' is already set up in '$HOME/.zshrc'. No changes needed."
else
  cat <<'EOL' >>"$HOME/.zshrc"

# >>> jenv >>>
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
# <<< jenv <<<
EOL
fi
echo_done

new_section_with_color "$color" "Enable 'jenv' 'export' plugin"
export PATH="$HOME/.jenv/bin:$PATH"
export PROMPT_COMMAND="" # Fix for unbound PROMPT_COMMAND in non-interactive shells
eval "$(jenv init -)"
jenv enable-plugin export
echo_done

# new_section_with_color "$color" "Restart shell"
# source "$HOME/.zshrc"
# echo_done

new_section_with_color "$color" "Remove current Java versions from 'jenv'"
rm -f ~/.jenv/shims/.jenv-shim
for v in $(jenv versions --bare); do
  jenv remove "$v"
done
rm -f ~/.jenv/version
echo_done

new_section_with_color "$color" "Check current state of 'jenv'"
jenv versions --verbose
# jenv doctor
# echo "Run 'jenv remove ...' if you get the error 'jenv: version ... is not installed'"

new_section_with_color "$color" "Show all 'java' command paths"

java_dirs=()
[[ -d /Library/Java/JavaVirtualMachines ]] && java_dirs+=("/Library/Java/JavaVirtualMachines")
[[ -d /opt/homebrew/Cellar ]] && java_dirs+=("/opt/homebrew/Cellar")

if [[ ${#java_dirs[@]} -eq 0 ]]; then
  exit_with_error "No Java installation directories found."
else
  java_paths=$(find "${java_dirs[@]}" \
    -type f \
    -path '*/Contents/Home/bin/*' \
    -name 'java' |
    sed 's:bin/java$::')
  echo "$java_paths"
fi
echo_done

new_section_with_color "$color" "Add all 'java' commands to 'jenv'"
while IFS= read -r java_path; do
  jenv add "$java_path"
done <<<"$java_paths"
echo_done

new_section_with_color "$color" "Set global Java version"
if [[ $version == '8' ]]; then
  global_version='1.8'
else
  global_version="$version"
fi
echo "Setting global Java version to '$global_version'..."
jenv global "$global_version"
echo_done

new_section_with_color "$color" "Check current state of 'jenv'"
echo "'jenv versions':"
jenv versions --verbose
echo
echo "'jenv doctor':"
jenv doctor || :

new_section_with_color "$color" "'java --version' output"
java --version
