#!/bin/bash
#
# Update, specify, and compute environment variables, such as
# PATH, or PS1 here.
#

# Environment customizations for users of https://github.com/sharkdp/bat
if which bat >/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

pg::require bat "Installation instructions: https://github.com/sharkdp/bat"
