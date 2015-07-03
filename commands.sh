#!/bin/bash
#
# Commands to execute in interactive terminals
#
# Executed last
# Not included in non-interactive terminals, like cron
# 

# Record command start times
# TODO This overwrites the DEBUG trap, breaks hermetic environment
# http://stackoverflow.com/q/16115144/113632 might help
trap '_time_command' DEBUG

# Set window title
tagtab

if $_PGEM_DEBUG
then
  # running _prompt_command directly has the added benefit
  # of setting PS1 before pgem_reload compares environments;
  # otherwise it would report that PS1 had been set to
  # the value of _PRE_PGEM_PS1
  echo PROMPT_COMMAND took:
  time _prompt_command
fi

# Set PS1
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_prompt_command"