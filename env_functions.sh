#!/bin/bash
#
# Useful functions to add to the ENV_INFO array to add functionality to your
# prompt. For example adding the following to your local.conf.sh, or to another
# gem's environment.sh will include your git project's status in the prompt:
#
#   ENV_INFO+=("git_prompt")

# Upper-case hostname, for title
hostname_title() {
  pg::err "hostname_title is deprecated, use prompt::short_hostname instead."
  pg::trace "$@"
  tr '[:lower:]' '[:upper:]' <<<"$HOSTNAME"
}

# Prints the current time, in purple
time_prompt() {
  local format_string=%I:%M:%S%p
  # Occasionally include the date in the timestamp
  # Is there a better approach to use here?
  if (( RANDOM % 100 == 0 )); then
    format_string="%F ${format_string}"
    fi
  pg::print -p PURPLE "$(date "+${format_string}")"
}

# Prints the current branch, colored by status, of a Mercurial repo
hg_prompt() {
  local repo
  repo=$(prompt::_find_repo .hg) || return 0
  cd "$repo" || return # so Mercurial doesn't have to do the same find we just did
  local branch num_heads heads
  # `hg branch` may be slow for large repos, read it from .hg
  { branch=$(<.hg/branch) || printf default; } 2>/dev/null
  num_heads=$(hg heads --template '{rev} ' 2> /dev/null | wc -w) || return 0
  if (( num_heads > 1 )); then
    heads='*'
  fi

  local color=GREEN
  if [[ -n "$(hg stat --modified --added --removed --deleted)" ]]; then
    color=LRED
  elif [[ -n "$(hg stat --unknown)" ]]; then
    color=PURPLE
  fi
  pg::print -p "$color" "${branch}${heads}"
  cd - > /dev/null
} && bc::cache hg_prompt PWD

# Prints the current branch, colored by status, of a Git repo
git_prompt() {
  local repo
  repo=$(prompt::_find_repo .git) || return 0
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
  elif cut -c2 <<<"$status" | grep -vq -e ' ' -e '?'; then
    color=RED # unstaged
  elif cut -c1 <<<"$status" | grep -vq -e ' ' -e '?'; then
    color=YELLOW # staged
  elif grep -q '?' <<<"$status"; then
    color=PURPLE # untracked
  fi
  pg::print -p "$color" "$label"
  cd - > /dev/null
} && bc::cache git_prompt PWD

# Prints the current screen session, if in one
screen_prompt() {
  if [[ -n "$STY" ]]; then
    pg::print -p CYAN "${STY#[0-9]*.}:${WINDOW}"
  fi
}
