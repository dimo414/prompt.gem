#!/bin/bash
#
# Useful functions to add to the ENV_INFO array to add functionality to your
# prompt. E.g.:
#
#   ENV_INFO+=("time_prompt")

# Prints the current time, in purple
time_prompt() {
  echo "$(pcolor PURPLE)\$(date +%I:%M:%S%p)$(pcolor)"
}

# Prints the current branch and state of a Mercurial repo
hg_prompt() {
  local repo
  repo=$(_find_repo .hg) || return 0
  cd "$repo" # so Mercurial doesn't have to do the same find we just did
  local branch
  branch=$(hg branch 2> /dev/null) || return 0

  local color=GREEN
  if [[ -n "$(hg stat --modified --added --removed --deleted)" ]]
  then
    color=LRED
  elif [[ -n "$(hg stat --unknown)" ]]
  then
    color=YELLOW
  fi
  echo "$(color $color)$branch$(color)"
}
