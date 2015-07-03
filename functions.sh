#!/bin/bash
# 
# Define bash functions here
# 
# Loaded after environment.sh and aliases.sh
# 

# Helper functions for color prompts
# You can specify the eight base colors by name,
# 8-bit colors by decimal value, and (where available)
# TrueColor 24-bit colors, as semicolon delimited decimals.
#
# If $2 has a value, sets the Bold parameter.
#
# http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
# http://unix.stackexchange.com/a/124409/19157
# https://gist.github.com/XVilka/8346728
color()
{
  local color=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local code
  case ${color//;/,} in # case doesn't seem to match semicolons
    bold) code=1
      ;;
    black) code=30
      ;;
    red) code=31
      ;;
    green) code=32
      ;;
    yellow) code=33
      ;;
    blue) code=34
      ;;
    purple) code=35
      ;;
    cyan) code=36
      ;;
    grey) code=37
      ;;
    *[0-9],*) code="38;2;$color";
      ;;
    *[0-9]*) code="38;5;$color"
      ;;
    *) code=0
  esac
  
  echo -en "\033[${2:+1;}${code}m"
}

# Wraps the color function in escaped square brackets,
# which is necessary in prompts (PS1, etc.) to tell
# bash the escape characters are non-printing.
pcolor()
{
  echo -n "\[$(color "$@")\]"
}

# "Tags" this shell, updating the window title and prompt
tagsh()
{
  if [ -n "$1" ] && [[ "$1" != '-' ]]
  then
    SHELL_TAG="$1"
  else
    SHELL_TAG=''
  fi
  echo -n -e "\033]0;${WINDOW_TITLE}${SHELL_TAG:+ - }${SHELL_TAG}\007"
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
  
  echo $output
}

# Records the time this method is called (relative to
# the shell).  Combined with the DEBUG trap this records
# when a terminal command starts.
# 
# http://stackoverflow.com/a/1862762/113632
_time_command()
{
  _PROMPT_COMMAND_START=${_PROMPT_COMMAND_START:-$SECONDS}
}

# Generates and sets PS1 and the window title
_prompt_command()
{
  # capture the exit code first, since we'll overwrite it
  local exit_code=$?
  
  # capture the execution time of the last command
  local runtime=$(($SECONDS - $_PROMPT_COMMAND_START))
  unset _PROMPT_COMMAND_START

  local exit_color=$((( $exit_code == 0 )) && echo GREEN || echo RED)
  local exit_symbol=$((( $exit_code == 0 )) && echo ✔ || echo ✘)
  
  local formatted_runtime="$((($runtime > 1)) && _format_seconds $runtime)"
  local formatted_runtime="${formatted_runtime:+$(pcolor yellow)$formatted_runtime$(pcolor) }"
  local exit_code_display="$(pcolor $exit_color)${exit_code}$(pcolor)"
  local last_command="[${formatted_runtime}${exit_code_display}]"
  
  local user_color=$([[ $EEUID == 0 ]] && echo RED BOLD || echo $HOST_COLOR)
  local machine="$(pcolor $user_color)\u$(pcolor)$(pcolor $HOST_COLOR)@\h$(pcolor)"
  local pwd="$(pcolor BLUE)\w$(pcolor)"
  local time_cmd="$(pcolor PURPLE)\$(date +%I:%M:%S%p)$(pcolor)"
  local shell_tag="${SHELL_TAG:+ $(color RED)${SHELL_TAG}$(color)}"
  local shell_env="[${machine}:${pwd} ${time_cmd}${shell_tag}]"
  
  local prompt='\$ '
  
  export PS1="\n${last_command} ${shell_env}\n${prompt}"
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