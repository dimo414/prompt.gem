#!/bin/bash
#
# Commands to execute in interactive terminals
#
# Executed last
# Not included in non-interactive terminals, like cron
#

append_array_once() {
  local array="${1:?}[@]" value="${2:?}" e
  for e in "${!array}"; do
    if [[ "$e" == "$value" ]]; then return; fi
  done
  eval "${1}+=('${value}')"
}

# To interoperate with bash-preexec, detect if it's already sourced and use it's preexec / precmd
# hooks instead of directly setting the PROMPT_COMMAND and DEBUG trap.
# See https://github.com/rcaloras/bash-preexec
# If it hasn't been installed yet that's OK; as of
# https://github.com/rcaloras/bash-preexec/commit/a1bab0c24b it will preserve any existing DEBUG
# and PROMPT_COMMAND settings. We just need to ensure we don't overwrite it. We also need to ensure
# the hooks aren't re-added by pgem_reload, so we can't just append to the bash-preexec arrays.
# shellcheck disable=SC2154
if [[ -n "$__bp_imported" ]]; then
  pg::log "bash-preexec found; not updating PROMPT_COMMAND and DEBUG trap"
  if [[ "$(type __bp_original_debug_trap 2>/dev/null)" != *"prompt::_command_start"* ]]; then
    append_array_once preexec_functions prompt::_command_start
  fi

  # Note https://github.com/rcaloras/bash-preexec/commit/c5f8d7fe did away with
  # __bp_original_prompt_command so we need to account for that and PROMPT_COMMAND
  if [[ "$PROMPT_COMMAND" != *"prompt::_set_ps1"* ]] && \
     [[ "$(type __bp_original_prompt_command 2>/dev/null)" != *"prompt::_set_ps1"* ]]; then
    append_array_once precmd_functions prompt::_set_ps1
  fi
else
  # CAPTURE_COMMAND_TIMES is a legacy setting, use OWN_DEBUG_TRAP instead
  if "${CAPTURE_COMMAND_TIMES:-"$OWN_DEBUG_TRAP"}"; then
    # Note this has no effect from pgem_reload, because functions can't overwrite external traps
    trap 'prompt::_command_start' DEBUG
  fi
  PROMPT_COMMAND="prompt::_set_ps1"
fi

if "${_PGEM_DEBUG:-false}"; then
  # running _prompt_command directly has the added benefit of setting PS1 before pgem_reload
  # compares environments; otherwise it would report that PS1 had been set to the value of
  # _PRE_PGEM_PS1
  echo "Constructing PS1 took:"
  time "prompt::_set_ps1"
fi

unset -f append_array_once
