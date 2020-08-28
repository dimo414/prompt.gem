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
  # TODO don't invoke notify-send directly, in order to support other platforms
  if ! command -v notify-send >/dev/null; then return; fi
  if (( $3 < DISPLAY_COMMAND_FINISHED_DIALOG )); then return; fi
  # Don't report certain (e.g. interactive) commands
  # TODO make this extensible
  if [[ "$1" =~ (less|ssh|vi|vim)\ .* ]]; then return; fi

  local icon='stock_dialog-info'
  local msg='Finished'
  if (( $2 > 127 && $2 < 192 )); then # signals, 1-64
    icon='stock_dialog-warning'
    msg='Terminated'
  elif (( $2 != 0 )); then
    icon='stock_dialog-error'
    msg='Failed'
  fi
  
  notify-send -i "$icon" "${msg} after ${4}: ${1}"
}

# Enables a blink(1) device with the color of the exit-code of long-running
# commands. The disable_blink1 function should also be added to ENV_INFO to
# turn the device off again.
notify_blink1() {
  if ! command -v blink1-tool >/dev/null; then return; fi
  # Turn off the blink(1) unconditionally, clearing previous commands
  blink1-tool --quiet --off
  if (( $3 < DISPLAY_COMMAND_FINISHED_DIALOG )); then return; fi
  # Don't report certain (e.g. interactive) commands
  if [[ "$1" =~ (less|ssh|vi|vim)\ .* ]]; then return; fi

  local color=--green
  if (( $2 > 127 && $2 < 192 )); then # signals, 1-64
    color=--magenta
  elif (( $2 != 0 )); then
    color=--red
  fi
  blink1-tool --quiet "$color"
}
