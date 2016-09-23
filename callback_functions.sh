#!/bin/bash
#
# Useful functions to add to the COMMAND_FINISHED_CALLBACKS array to add
# functionality to your prompt. E.g.:
#
#   COMMAND_FINISHED_CALLBACKS+=("notify_desktop")
#
# Callback arguments:
#   1: command
#   2: exit code
#   3: runtime seconds (int)
#   4: formatted runtime (human-readable string)

# Triggers a desktop notification (Ubuntu-only for now) when long-running
# commands finish.
notify_desktop() {
  if (( $3 < DISPLAY_COMMAND_FINISHED_DIALOG )); then return; fi
  # Don't report certain (e.g. interactive) commands
  # TODO make this extensible
  if [[ "$1" =~ (vi|vim|ssh)\ .* ]]; then return; fi

  if (( $2 == 0 ))
  then
    local icon='stock_dialog-info'
    local msg='Finished'
  else
    local icon='stock_dialog-error'
    local msg='Failed'
  fi

  notify-send -i $icon "$msg after $4: $1"
}
