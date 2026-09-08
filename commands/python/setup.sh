#!/usr/bin/env bash
set -euo pipefail

##? Set up Python on your computer.
##?
##? Usage:
##?   python setup [--miniforge-version=VERSION --no-update]
##?
##? Options:
##?   --miniforge-version=VERSION  Miniforge version from https://github.com/conda-forge/miniforge/releases/ [default: latest]
##?   --no-update                  Do not update packages with conda and do not install Python packages.
##?
##? Examples:
##?   python setup --miniforge-version=24.3.0-0
##?   python setup --miniforge-version=latest

source "${CLI_DIR}/core/helpers.sh"
parse_help "$@"
declare miniforge_version no_update

color="blue"

if is_mac && command_exists brew; then
  new_section_with_color "$color" "Install miniforge with Homebrew"
  if [[ "$miniforge_version" != "latest" ]]; then
    echo_warn "Miniforge version = '$miniforge_version' will be ignored. Installing the latest version instead."
  fi
  brew install miniforge
  conda_bin="/opt/homebrew/Caskroom/miniforge/base/condabin/conda"
  # same as: /opt/homebrew/Caskroom/miniforge/base/bin/conda
  echo_done
else

  if is_mac; then
    os="MacOSX"
  else
    os="Linux"
  fi

  arch="$(uname -m)"

  if [[ $miniforge_version == "latest" ]]; then
    miniforge_fname="Miniforge3-${os}-${arch}.sh"
    source_url="https://github.com/conda-forge/miniforge/releases/latest/download/${miniforge_fname}"
  else
    miniforge_fname="Miniforge3-${miniforge_version}-${os}-${arch}.sh"
    source_url="https://github.com/conda-forge/miniforge/releases/download/${miniforge_version}/${miniforge_fname}"
  fi

  destination_dir="${HOME}/Downloads"
  local_file="${destination_dir}/${miniforge_fname}"

  new_section_with_color "$color" "Download '$miniforge_fname' into '$destination_dir'"
  if [[ ! -f $local_file ]]; then
    wget -P "$destination_dir" "$source_url"
  else
    echo "File '$local_file' already exists."
  fi
  echo_done

  new_section_with_color "$color" "Install Python with miniforge"
  bash "$local_file" -bu
  echo_done

  conda_bin="${HOME}/miniforge3/condabin/conda"
fi

new_section_with_color "$color" "Run init command"
"$conda_bin" init zsh
echo_done

new_section_with_color "$color" "Add 'ipykernel' to default packages"
"$conda_bin" config --add create_default_packages ipykernel
echo_done

if ! $no_update; then
  new_section_with_color "$color" "Update packages"
  "$conda_bin" update -yn base conda
  "$conda_bin" update -yn base --all
  echo_done

  new_section_with_color "$color" "Install Python packages"
  "$conda_bin" install -yn base \
    boto3 \
    jupyterlab \
    jupyterlab_execute_time \
    matplotlib \
    nb_conda_kernels \
    pandas \
    pipdeptree \
    pytest \
    pytest-xdist \
    seaborn \
    tabulate \
    toolz
  echo_done
fi
