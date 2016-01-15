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
