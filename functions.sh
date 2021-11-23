#!/bin/bash
#
# Define bash functions here
#
# Loaded after environment.sh and aliases.sh
#

# Log-style functions with colored output
# TODO these are not really very useful, delete after Feb 2022
note()  { pg::err "note function is deprecated, use pg::print instead";  pg::print GREEN  'NOTE:  ' OFF "$*"; }
warn()  { pg::err "warn function is deprecated, use pg::print instead";  pg::print YELLOW 'WARN:  ' OFF "$*"; }
error() { pg::err "error function is deprecated, use pg::print instead"; pg::print RED    'ERROR: ' OFF "$*"; }

# "Tags" this shell, updating the window title and prompt.
tagsh() {
  _SHELL_TAG="$*"
}

prompt::_update_title() {
  local title_info
  printf -v title_info '%s - ' "${_TITLE_PARTS[@]}" ${_SHELL_TAG:+"$_SHELL_TAG"}
  # shellcheck disable=SC2154 # https://github.com/koalaman/shellcheck/issues/2053
  printf '\e]0;%s%s\a' "${title_prefix:+"[${title_prefix}] "}" "${title_info% - }"
}

prompt::_shorten() {
  if (( $# == 1 )); then echo "$1"; return; fi
  local value="${1:?}"; shift
  sed -f <(printf '%s\n' "$@") <<<"$value"
}

# Shortens pwd to a more readable format
prompt::short_pwd() {
  prompt::_shorten "$PWD" "${HIDE_PATHS[@]}"
}

# Shortens hostname to a more readable format
prompt::short_hostname() {
  # Can swap to ${HOSTNAME^^} once we no longer support Bash 3
  prompt::_shorten "$(tr '[:lower:]' '[:upper:]' <<<"$HOSTNAME")" "${HIDE_HOSTS[@]}"
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
# By default writes to $duration; pass a different variable name as $2 if needed.
prompt::_format_seconds() {
  local _duration=$1 _var=${2:-duration}
  local _output="$((_duration % 60))s"
  ((_duration /= 60))

  ((_duration > 0)) && _output="$((_duration % 60))m $_output"
  ((_duration /= 60))

  ((_duration > 0)) && _output="$((_duration % 24))h $_output"
  ((_duration /= 24))

  ((_duration > 0)) && _output="${_duration}d $_output"

  printf -v "$_var" '%s' "$_output"
}

# Invoked as (part of) the DEBUG trap, to record the time the user-invoked command is started.
# http://stackoverflow.com/a/1862762/113632
# Also updates the title with the running command
prompt::_command_start() {
  # Ignore while tab-completing or running prompt::_set_ps1
  if [[ -n "$COMP_LINE" ]] || [[ -n "$_BUILD_PROMPT" ]]; then return; fi
  local cmd="${BASH_COMMAND%% *}"
  title_prefix="${cmd##*/}" prompt::_update_title
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
  if (( exit_code > 128 && exit_code <= 128+64 )); then # signals, 1-64
    exit_color=PURPLE
  elif (( exit_code != 0 )); then
    exit_color=RED
  fi

  # calling history appears to update the history file as a side-effect
  local last_command=$(HISTTIMEFORMAT='' history 1 | sed '1 s/^ *[0-9]\+[* ] //')
  local formatted_runtime
  prompt::_format_seconds "$runtime" formatted_runtime

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

  local cmd cmd_result env_parts=() env
  _TITLE_PARTS=() # not local
  # shellcheck disable=SC2153
  for cmd in "${TITLE_INFO[@]}"; do
    cmd_result="$("$cmd")"
    if [[ -n "$cmd_result" ]]; then _TITLE_PARTS+=("${cmd_result}"); fi
  done
  prompt::_update_title
  # shellcheck disable=SC2153
  for cmd in "${ENV_INFO[@]}"; do
    cmd_result="$("$cmd")"
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

