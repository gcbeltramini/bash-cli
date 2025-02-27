#!/usr/bin/env bash
set -euo pipefail

use_gnu_tool() {
  # Define a function that calls the GNU version of the command, if it exists.
  #
  # Usage:
  #   use_gnu_tool <gnu_command_name>
  local -r gnu_cmd=$1
  local -r cmd_name="${gnu_cmd#g}" # remove the 'g' prefix

  if command -v "$gnu_cmd" >/dev/null; then
    eval "$cmd_name() { $gnu_cmd \"\$@\"; }"
  fi
}

use_all_gnu_tools() {
  # Alias all GNU utilities when they exist.
  #
  # Usage:
  #   use_all_gnu_tools

  local -r gnu_commands=(
    # coreutils (in "$(brew --prefix)/Cellar/coreutils/"*"/bin/g"*):
    # "g[" # fails in 'use_gnu_tool', but we can use "gtest" instead, if necessary
    gb2sum
    gbase32
    gbase64
    gbasename
    gbasenc
    gcat
    gchcon
    gchgrp
    gchmod
    gchown
    gchroot
    gcksum
    gcomm
    gcp
    gcsplit
    gcut
    gdate
    gdd
    gdf
    gdir
    gdircolors
    gdirname
    gdu
    gecho
    genv
    gexpand
    gexpr
    gfactor
    gfalse
    gfmt
    gfold
    ggroups
    ghead
    ghostid
    gid
    ginstall
    gjoin
    gkill
    glink
    gln
    glogname
    gls
    gmd5sum
    gmkdir
    gmkfifo
    gmknod
    gmktemp
    gmv
    gnice
    gnl
    gnohup
    gnproc
    gnumfmt
    god
    gpaste
    gpathchk
    gpinky
    gpr
    gprintenv
    gprintf
    gptx
    gpwd
    greadlink
    grealpath
    grm
    grmdir
    gruncon
    gseq
    gsha1sum
    gsha224sum
    gsha256sum
    gsha384sum
    gsha512sum
    gshred
    gshuf
    gsleep
    gsort
    gsplit
    gstat
    gstdbuf
    gstty
    gsum
    gsync
    gtac
    gtail
    gtee
    gtest
    gtimeout
    gtouch
    gtr
    gtrue
    gtruncate
    gtsort
    gtty
    guname
    gunexpand
    guniq
    gunlink
    guptime
    gusers
    gvdir
    gwc
    gwho
    gwhoami
    gyes

    # findutils (in "$(brew --prefix)/Cellar/findutils/"*"/bin/g"*):
    gfind
    glocate
    gupdatedb
    gxargs

    # gawk (in "$(brew --prefix)/Cellar/gawk/"*"/bin/g"*):
    gawk

    # gnu-sed (in "$(brew --prefix)/Cellar/gnu-sed/"*"/bin/g"*):
    gsed

    # grep (in "$(brew --prefix)/Cellar/grep/"*"/bin/g"*):
    gegrep
    gfgrep
    ggrep
  )

  for cmd in "${gnu_commands[@]}"; do
    use_gnu_tool "$cmd"
  done
}

use_all_gnu_tools
