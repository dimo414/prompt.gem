#!/bin/bash
#
# Useful functions to add to the ENV_INFO array to add functionality to your
# prompt. For example adding the following to your local.conf.sh, or to another
# gem's environment.sh will include your git project's status in the prompt:
#
#   ENV_INFO+=("git_prompt")

# Prints the current time, in purple
time_prompt() {
  printf "$(pcolor PURPLE)%s$(pcolor)" "$(date +%I:%M:%S%p)"
}

# Prints the current branch, colored by status, of a Mercurial repo
hg_prompt() {
  local repo
  repo=$(_find_repo .hg) || return 0
  cd "$repo" || return # so Mercurial doesn't have to do the same find we just did
  local branch
  branch=$(hg branch 2> /dev/null) || return 0

  local color=GREEN
  if [[ -n "$(hg stat --modified --added --removed --deleted)" ]]; then
    color=LRED
  elif [[ -n "$(hg stat --unknown)" ]]; then
    color=PURPLE
  fi
  printf "$(pcolor $color)%s$(pcolor)" "$branch"
  cd - > /dev/null
} && _cache hg_prompt PWD

# Prints the current branch, colored by status, of a Git repo
git_prompt() {
  local repo
  repo=$(_find_repo .git) || return 0
  cd "$repo" || return # so Git doesn't have to do the same find we just did
  local label
  # http://stackoverflow.com/a/12142066/113632
  label=$(git rev-parse --abbrev-ref HEAD 2> /dev/null) || return 0
  if [[ "$label" == "HEAD" ]]; then
    # http://stackoverflow.com/a/18660163/113632
    label=$(git describe --tags --exact-match 2> /dev/null)
  fi

  local color
  local status
  status=$(git status --porcelain | cut -c1-2)
  if [[ -z "$status" ]]; then
    color=GREEN
  elif echo "$status" | cut -c2 | grep -vq -e ' ' -e '?'; then
    color=RED # unstaged
  elif echo "$status" | cut -c1 | grep -vq -e ' ' -e '?'; then
    color=YELLOW # staged
  elif echo "$status" | grep -q '?'; then
    color=PURPLE # untracked
  fi
  printf "$(pcolor $color)%s$(pcolor)" "$label"
  cd - > /dev/null
} && _cache git_prompt PWD

# Prints the current screen session, if in one
screen_prompt() {
  if [[ -n "$STY" ]]; then
    printf "$(pcolor CYAN)%s$(pcolor)" "${STY#[0-9]*.}:${WINDOW}"
  fi
}
