#!/bin/bash
#
# Define bash functions here
#
# Loaded after environment.sh and aliases.sh
#

# Helper functions for color prompts
# You can specify common colors by name (see case
# statement below), 8-bit colors by decimal value,
# and (where available) TrueColor 24-bit colors
# as semicolon delimited decimals.
#
# With no arguments, resets the color to default.
#
# The second argument can set formatting, such as bold,
# dim, and invert. Use default as the color to just
# apply formatting.
#
# http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
# http://unix.stackexchange.com/a/124409/19157
# https://gist.github.com/XVilka/8346728
# See https://github.com/alacritty/alacritty/wiki/Scripts for a nice color table script
# TODO redesign and move to ProfileGem
color() {
  local color format code attr
  color=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  format=$(tr '[:upper:]' '[:lower:]' <<<"$2")
  case ${color//;/,} in # case doesn't seem to match semicolons
    black)      code=30 ;;
    dgrey)      code=90 ;;
    red)        code=31 ;;
    lred)       code=91 ;;
    green)      code=32 ;;
    lgreen)     code=92 ;;
    yellow)     code=33 ;;
    lyellow)    code=93 ;;
    blue)       code=34 ;;
    lblue)      code=94 ;;
    purple)     code=35 ;;
    lpurple)    code=95 ;;
    cyan)       code=36 ;;
    lcyan)      code=96 ;;
    grey|lgrey) code=37 ;;
    white)      code=97 ;;
    d|default)  code=39 ;;
    *[0-9],*)   code="38;2;$color" ;;
    *[0-9]*)    code="38;5;$color" ;;
    ''|none)    code=0 ;; # reset
    *) echo "Invalid color $1" >&2 && return 1 ;;
  esac
  # TODO support multiple formattings, like BOLD UNDERLINE
  case $format in
    bold|bright) attr=1 ;;
    dim) attr=2 ;;
    italic) attr=3 ;; # limited support
    underline) attr=4 ;;
    blink) attr=5 ;; # you monster
    reverse) attr=7 ;;
    hide|hidden) attr=8 ;;
    strike) attr=9 ;; # limited support
    '') : ;; # no formatting
    *) echo "Invalid format $2" >&2 && return 1 ;;
  esac

  printf '\033[%s%sm' "${attr:+$attr;}" "${code}"
}

# Wraps the color function in escaped square brackets,
# which is necessary in prompts (PS1, etc.) to tell
# bash the escape characters are non-printing.
pcolor() {
  # TODO \001...\002 doesn't appear to work on Ubuntu
  #printf '\001%s\002' "$(color "$@")"
  printf '\[%s\]' "$(color "$@")"
}

# Log-style functions with colored output
note() { echo "$(color GREEN)NOTE:$(color)  $*"; }
warn() { echo "$(color YELLOW)WARN:$(color)  $*"; }
error() { echo "$(color RED)ERROR:$(color) $*"; }

# "Tags" this shell, updating the window title and prompt.
# Tag is stored in _SHELL_TAG so the tag can be restored
# after other different applications (e.g. ssh) overwrites it.
tagsh() {
  _SHELL_TAG="$*"
  local title_info title_cmd cmd_result title_parts=()

  # shellcheck disable=SC2153
  for title_cmd in "${TITLE_INFO[@]}"; do
    cmd_result="$($title_cmd)"
    if [[ -n "$cmd_result" ]]; then title_parts+=("$cmd_result"); fi
  done
  if [[ -n "$_SHELL_TAG" ]]; then title_parts+=("$_SHELL_TAG"); fi

  printf -v title_info '%s - ' "${title_parts[@]}"
  printf '\033]0;%s\007' "${title_info% - }"
}

# Tags the shell tab correctly upon exiting an SSH session
# TODO is this actually necessary anymore? _prompt_command calls tagsh every time
if [[ "$(type -t ssh)" != "alias" ]]; then # don't create if user has an ssh alias
ssh() {
  command ssh "$@"
  local ret=$?
  tagsh "$_SHELL_TAG"
  return "$ret"
}
fi

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

# TODO rename these prompt::_command_timing and prompt::_set_ps1

# Records the time this method is called (relative to
# the shell).  Combined with the DEBUG trap this records
# when a terminal command starts.
# 
# http://stackoverflow.com/a/1862762/113632
_time_command() {
  # Ignore while tab-completing or running _prompt_command
  if [[ -n "$COMP_LINE" ]] || [[ -n "$_BUILD_PROMPT" ]]; then return; fi
  _PROMPT_COMMAND_START=${_PROMPT_COMMAND_START:-$SECONDS}
}

# Generates and sets PS1 and the window title
# shellcheck disable=SC2155
_prompt_command() {
  # capture the exit code first, since we'll overwrite it
  local exit_code=$?
  _BUILD_PROMPT=true

  # capture the execution time of the last command
  local runtime=$(( SECONDS - ${_PROMPT_COMMAND_START:-$SECONDS} ))
  unset _PROMPT_COMMAND_START

  tagsh "$_SHELL_TAG"

  local exit_color=GREEN
  if (( exit_code > 127 && exit_code < 192 )); then # signals, 1-64
    exit_color=PURPLE
  elif (( exit_code != 0 )); then
    exit_color=RED
  fi

  # calling history appears to update the history file as a side-effect
  local last_command=$(HISTTIMEFORMAT='' history 1 | sed '1 s/^ *[0-9]\+[* ] //')
  local formatted_runtime=$(prompt::_format_seconds "$runtime")

  for callback in "${COMMAND_FINISHED_CALLBACKS[@]}"; do
    # Trigger callbacks asynchronously and in the background; these callbacks
    # should not block the next prompt from being rendered.
    ("$callback" "$last_command" "$exit_code" "$runtime" "$formatted_runtime" &)
  done

  local runtime_display
  if ((runtime >= DISPLAY_COMMAND_TIME_THRESHOLD)); then
    runtime_display="$(pcolor YELLOW)$formatted_runtime$(pcolor)"
  fi

  local exit_code_display="$(pcolor "$exit_color")${exit_code}$(pcolor)"

  local user_color="$HOST_COLOR"
  if (( EUID == 0 )); then user_color='LRED REVERSE'; fi
  local machine="$(pcolor "$user_color")\u$(pcolor "$HOST_COLOR")@\h$(pcolor)"
  local pwd="$(pcolor LBLUE)$(prompt::short_pwd)$(pcolor)"

  local env_cmd cmd_result env_parts=() env
  # shellcheck disable=SC2153
  for env_cmd in "${ENV_INFO[@]}"; do
    cmd_result="$($env_cmd)"
    if [[ -n "$cmd_result" ]]; then env_parts+=("${cmd_result}"); fi
  done
  if [[ -n "${_SHELL_TAG}" ]]; then
    env_parts+=("$(pcolor RED)${_SHELL_TAG}$(pcolor)")
  fi
  (( ${#env_parts[@]} == 0 )) || printf -v env ' %s' "${env_parts[@]}"

  printf -v PS1 '\n[%s%s] [%s:%s%s]\n%s ' \
    "${runtime_display:+${runtime_display} }" "${exit_code_display}" \
    "${machine}" "${pwd}" "${env}" \
    '\$'

  # Done building prompt - make sure this line is last
  unset _BUILD_PROMPT
}

# Include common functions users can add to ENV_INFO
source env_functions.sh
# Include common functions users can add to COMMAND_FINISHED_CALLBACKS
source callback_functions.sh

