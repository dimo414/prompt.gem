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
color()
{
  local color format code attr
  color=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  format=$(echo "$2" | tr '[:upper:]' '[:lower:]')
  case ${color//;/,} in # case doesn't seem to match semicolons
    black) code=30 ;;
    dgrey) code=90 ;;
    red) code=31 ;;
    lred) code=91 ;;
    green) code=32 ;;
    lgreen) code=92 ;;
    yellow) code=33 ;;
    lyellow) code=93 ;;
    blue) code=34 ;;
    lblue) code=94 ;;
    purple) code=35 ;;
    lpurple) code=95 ;;
    cyan) code=36 ;;
    lcyan) code=96 ;;
    grey|lgrey) code=37 ;;
    white) code=97 ;;
    d|default) code=39 ;;
    *[0-9],*) code="38;2;$color" ;;
    *[0-9]*) code="38;5;$color" ;;
    '') code=0 ;; # reset
    *) echo "Invalid color $color" >&2 && return 1 ;;
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
    *) echo "Invalid format $format" >&2 && return 1 ;;
  esac

  printf '\033[%s%sm' "${attr:+$attr;}" "${code}"
}

# Log-style functions with colored output
note() { echo "$(color GREEN)NOTE:$(color)  $@"; }
warn() { echo "$(color YELLOW)WARN:$(color)  $@"; }
error() { echo "$(color RED)ERROR:$(color) $@"; }

# Wraps the color function in escaped square brackets,
# which is necessary in prompts (PS1, etc.) to tell
# bash the escape characters are non-printing.
pcolor()
{
  # TODO \001...\002 doesn't appear to work on Ubuntu
  #printf '\001%s\002' "$(color "$@")"
  printf '\[%s\]' "$(color "$@")"
}

# "Tags" this shell, updating the window title and prompt.
# Using '-' as the tag restores the previous window title
# after a different application (e.g. ssh) overwrites it.
tagsh()
{
  if [[ "$#" -ne "0" ]] && [[ "$@" != '-' ]]
  then
    SHELL_TAG="$*"
  elif [[ "$#" -eq "0" ]]
  then
    SHELL_TAG=''
  fi
  echo -n -e "\033]0;${WINDOW_TITLE}${SHELL_TAG:+ - }${SHELL_TAG}\007"
}

# Tags the shell tab correctly upon exiting an SSH session
ssh()
{
  # intentionally using which to not match this function
  # perhaps can use pgem_decorate instead?
  $(which ssh) "$@"
  local ret=$?
  tagsh -
  return $ret
}

# Shortens pwd to a more readable format
short_pwd() {
  [[ ${#HIDE_PATHS[@]} == 0 ]] && pwd && return
  
  pwd | sed -f <(for script in "${HIDE_PATHS[@]}"; do echo "$script"; done)
}

# Given a function, and optionally a list of environment variables,
# Decorates the function with a short-term caching mechanism, useful
# for improving the responsiveness of functions used in the prompt,
# at the expense of slightly stale data.
#
# Suggested usage:
#   expensive_func() {
#     ...
#   } && _cache expensive_func PWD
#
# This will avoid re-calling expensive_func with the same arguments and in the
# same working directory too often.
_cache() {
  $ENABLE_CACHED_COMMANDS || return 0

  mkdir -p "$CACHE_DIR"

  func="${1:?"Must provide a function name to cache"}"
  shift
  copy_function "${func}" "_orig_${func}" || return
  local env="$func:"
  for v in "$@"
  do
    env="$env:\$$v"
  done
  eval "$(cat <<EOF
    _cache_$func() {
      : "\${cachepath:?"Must provide a cachepath to link to as an environment variable"}"
      mkdir -p "\$CACHE_DIR"
      local cmddir=\$(mktemp -d -p "\$CACHE_DIR")
      _orig_$func "\$@" > "\$cmddir/out" 2> "\$cmddir/err"; echo \$? > "\$cmddir/exit"
      ln -sfn "\$cmddir" "\$cachepath" # atomic
    }
EOF
  )"
  eval "$(cat <<EOF
    $func() {
      \$ENABLE_CACHED_COMMANDS || { _orig_$func "\$@"; return; }
      # Clean up stale caches in the background
      (find "\$CACHE_DIR" -not -path "\$CACHE_DIR" -not -newermt '-1 minute' -delete &)

      local arghash=\$(echo "\${*}$env" | md5sum | tr -cd '0-9a-fA-F')
      local cachepath=\$CACHE_DIR/\$arghash

      # Capture output once to avoid races
      local out err exit
      out=\$(cat "\$cachepath/out" 2>/dev/null)
      err=\$(cat "\$cachepath/err" 2>/dev/null)
      exit=\$(cat "\$cachepath/exit" 2>/dev/null)
      if [[ "\$exit" == "" ]]
      then
        # No cache, execute in foreground
        _cache_$func "\$@"
        out=\$(cat "\$cachepath/out")
        err=\$(cat "\$cachepath/err")
        exit=\$(cat "\$cachepath/exit" || echo 255)
      elif [[ "\$(find "\$CACHE_DIR" -path "\$cachepath/exit" -newermt '-10 seconds')" == "" ]]
      then 
        # Cache exists but is old, refresh in background
        ( _cache_$func "\$@" & )
      fi
      # Output cached result, less than 10 seconds old
      # These files still disapear from time to time, so we silence errors
      echo "\$out"
      echo "\$err" >&2
      return "\$exit"
    }
EOF
  )"
}

# Given a directory name (like .hg or .git) look through the pwd for such a repo
_find_repo() {
  local dir
  dir=$(pwd)
  while [[ "$dir" != "/" ]]
  do
    [[ -d "$dir/$1" ]] && echo "$dir" && return
    dir="$(dirname "$dir")"
  done
  return 1
}

# Given a number of seconds formats it as a human-readable string.
_format_seconds()
{
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

# Records the time this method is called (relative to
# the shell).  Combined with the DEBUG trap this records
# when a terminal command starts.
# 
# http://stackoverflow.com/a/1862762/113632
_time_command()
{
  # Ignore while tab-completing, or running _prompt_command
  ([ -n "$COMP_LINE" ] || [ -n "$_BUILD_PROMPT" ]) && return
 
  _PROMPT_COMMAND_START=${_PROMPT_COMMAND_START:-$SECONDS}
}

# Generates and sets PS1 and the window title
# shellcheck disable=SC2155
_prompt_command()
{
  # capture the exit code first, since we'll overwrite it
  local exit_code=$?
  _BUILD_PROMPT=true

  # capture the execution time of the last command
  local runtime=$((SECONDS - ${_PROMPT_COMMAND_START:-$SECONDS}))
  unset _PROMPT_COMMAND_START

  local exit_color=$( (( exit_code == 0 )) && echo GREEN || echo RED)
  # shellcheck disable=SC2034
  local exit_symbol=$( (( exit_code == 0 )) && echo ✔ || echo ✘)

  local formatted_runtime="$( ((runtime >= 5)) && _format_seconds $runtime)"
  local formatted_runtime="${formatted_runtime:+$(pcolor yellow)$formatted_runtime$(pcolor) }"
  local exit_code_display="$(pcolor $exit_color)${exit_code}$(pcolor)"
  local last_command="[${formatted_runtime}${exit_code_display}]"

  local user_color=$( ((EUID == 0)) && echo LRED BOLD || echo "$HOST_COLOR")
  local machine="$(pcolor $user_color)\u$(pcolor)$(pcolor $HOST_COLOR)@\h$(pcolor)"
  local pwd="$(pcolor LBLUE)$(short_pwd)$(pcolor)"

  local env_info=''
  local env_cmd
  for env_cmd in "${ENV_INFO[@]}"
  do
    cmd_result="$($env_cmd)"
    env_info="${env_info}${cmd_result:+ $cmd_result}"
  done

  local shell_tag="${SHELL_TAG:+ $(color RED)${SHELL_TAG}$(color)}"
  local shell_env="[${machine}:${pwd}${env_info}${shell_tag}]"
  
  local prompt='\$ '
  
  export PS1="\n${last_command} ${shell_env}\n${prompt}"
  
  # Done building prompt - make sure this line is last
  unset _BUILD_PROMPT
}

# Prints a table of bash colors and how they look
# From http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
_color_table()
{
  local T='gYw'   # The test text
  local FG; local BG

  echo -e "\n                 40m     41m     42m     43m\
     44m     45m     46m     47m";

  for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
             '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
             '  36m' '1;36m' '  37m' '1;37m';
    do FG=${FGs// /}
    echo -en " $FGs \033[$FG  $T  \033[0m"
    for BG in 40m 41m 42m 43m 44m 45m 46m 47m;
      do echo -en " \033[$FG\033[$BG  $T  \033[0m";
    done
    echo;
  done
  echo
}


# Include common functions users can add to ENV_INFO
. env_functions.sh
