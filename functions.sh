#!/bin/bash
#
# Define bash functions here
#
# Loaded after environment.sh and aliases.sh
#

# TODO add a deprecation warning
# TODO delete these functions after March 2021
color() {
  local color format _pg_style
  color=$(tr '[:lower:]' '[:upper:]' <<<"${1:-OFF}")
  format=$(tr '[:lower:]' '[:upper:]' <<<"$2")
  pg::style "${color}${format:+:${format}}"
  printf '%s' "$_pg_style"
}
pcolor() { printf '\[%s\]' "$(color "$@")"; }

# Log-style functions with colored output
# TODO these are not really very useful, delete?
note()  { pg::print GREEN  'NOTE:  ' OFF "$*"; }
warn()  { pg::print YELLOW 'WARN:  ' OFF "$*"; }
error() { pg::print RED    'ERROR: ' OFF "$*"; }

# "Tags" this shell, updating the window title and prompt.
# Tag is stored in _SHELL_TAG so the tag can be restored
# after other different applications (e.g. ssh) overwrites it.
tagsh() {
  _SHELL_TAG="$*"
  pg::_update_title
}

pg::_update_title() {
  local title_info title_cmd cmd_result title_parts=()

  # shellcheck disable=SC2153
  for title_cmd in "${TITLE_INFO[@]}"; do
    cmd_result="$($title_cmd)"
    if [[ -n "$cmd_result" ]]; then title_parts+=("$cmd_result"); fi
  done
  if [[ -n "$_SHELL_TAG" ]]; then title_parts+=("$_SHELL_TAG"); fi

  printf -v title_info '%s - ' "${title_parts[@]}"
  printf '\033]0;%s%s\007' "${title_prefix:+"[${title_prefix}] "}" "${title_info% - }"
}

# Shortens pwd to a more readable format
prompt::short_pwd() {
  if (( ${#HIDE_PATHS[@]} == 0 )); then echo "$PWD"; return; fi
  sed -f <(printf '%s\n' "${HIDE_PATHS[@]}") <<<"$PWD"
}

# Given a directory name (like .hg or .git) look through the pwd for such a repo
prompt::_find_repo() {
  local dir="$PWD" repoMarker="${1:?Must specify the marker that indicates a repo}"
  until [[ -z "$dir" ]];  do
    if [[ -e "$dir/$repoMarker" ]]; then echo "$dir"; return; fi
    dir="${dir%/*}"
  done
  return 1
}

# Given a number of seconds formats it as a human-readable string.
prompt::_format_seconds() {
  local duration=$1
  local output="$((duration % 60))s"
  ((duration /= 60))

  ((duration > 0)) && output="$((duration % 60))m $output"
  ((duration /= 60))

  ((duration > 0)) && output="$((duration % 24))h $output"
  ((duration /= 24))

  ((duration > 0)) && output="${duration}d $output"

  echo "$output"
}

# TODO delete these artifacts after Jan 2021
_time_command() { :; }
_prompt_command() { :; }

# Invoked as (part of) the DEBUG trap, to record the time the user-invoked command is started.
# http://stackoverflow.com/a/1862762/113632
# Also updates the title with the running command
prompt::_command_start() {
  # Ignore while tab-completing or running prompt::_set_ps1
  if [[ -n "$COMP_LINE" ]] || [[ -n "$_BUILD_PROMPT" ]]; then return; fi
  title_prefix="${BASH_COMMAND%% *}" pg::_update_title
  _PROMPT_COMMAND_START=${_PROMPT_COMMAND_START:-$SECONDS}
}

# Generates and sets PS1 and the window title
# shellcheck disable=SC2155
prompt::_set_ps1() {
  # capture the exit code first, since we'll overwrite it
  local exit_code=$?
  _BUILD_PROMPT=true

  # capture the execution time of the last command
  local runtime=$(( SECONDS - ${_PROMPT_COMMAND_START:-$SECONDS} ))
  unset _PROMPT_COMMAND_START

  local exit_color=GREEN
  if (( exit_code > 127 && exit_code < 192 )); then # signals, 1-64
    exit_color=PURPLE
  elif (( exit_code != 0 )); then
    exit_color=RED
  fi

  # calling history appears to update the history file as a side-effect
  local last_command=$(HISTTIMEFORMAT='' history 1 | sed '1 s/^ *[0-9]\+[* ] //')
  local formatted_runtime=$(prompt::_format_seconds "$runtime")

  pg::_update_title
  for callback in "${COMMAND_FINISHED_CALLBACKS[@]}"; do
    # Trigger callbacks asynchronously and in the background; these callbacks
    # should not block the next prompt from being rendered.
    ("$callback" "$last_command" "$exit_code" "$runtime" "$formatted_runtime" &)
  done

  local _pg_style _pg_style_off runtime_display
  pg::style -p OFF _pg_style_off
  if ((runtime >= DISPLAY_COMMAND_TIME_THRESHOLD)); then
    pg::style -p YELLOW
    runtime_display="${_pg_style}${formatted_runtime}${_pg_style_off}"
  fi

  pg::style -p "$exit_color"
  local exit_code_display="${_pg_style}${exit_code}${_pg_style_off}"

  local machine pwd
  if (( EUID == 0 )); then
    local root_style
    pg::style -p LRED:REVERSE root_style
    pg::style -p "OFF:${HOST_COLOR}"
    machine="${root_style}\u${_pg_style}@\h${_pg_style_off}"
  else
    pg::style -p "${HOST_COLOR}"
    machine="${_pg_style}\u@\h${_pg_style_off}"
  fi

  pg::style -p LBLUE
  pwd="${_pg_style}$(prompt::short_pwd)${_pg_style_off}"

  local env_cmd cmd_result env_parts=() env
  # shellcheck disable=SC2153
  for env_cmd in "${ENV_INFO[@]}"; do
    cmd_result="$($env_cmd)"
    if [[ -n "$cmd_result" ]]; then env_parts+=("${cmd_result}"); fi
  done
  if [[ -n "${_SHELL_TAG}" ]]; then
    pg::style -p RED
    env_parts+=("${_pg_style}${_SHELL_TAG}${_pg_style_off}")
  fi
  (( ${#env_parts[@]} == 0 )) || printf -v env ' %s' "${env_parts[@]}"

  printf -v PS1 '\n[%s%s] [%s:%s%s]\n\\$ ' \
    "${runtime_display:+${runtime_display} }" "${exit_code_display}" \
    "${machine}" "${pwd}" "${env}"

  # Done building prompt - make sure this line is last
  unset _BUILD_PROMPT
}

# Include common functions users can add to ENV_INFO
source env_functions.sh
# Include common functions users can add to COMMAND_FINISHED_CALLBACKS
source callback_functions.sh

