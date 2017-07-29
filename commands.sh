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
# It also doesn't undo itself if CAPTURE_COMMAND_TIMES is turned
# off and pgem_reload is called. That might be harder.
$CAPTURE_COMMAND_TIMES && trap '_time_command' DEBUG

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
# we have to commandeer PROMPT_COMMAND, not just extend it,
# since the exit code behavior has to be first, and the command
# timing behavior has to be last.
PROMPT_COMMAND="_prompt_command"
