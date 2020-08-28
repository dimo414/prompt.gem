#!/bin/bash
#
# Commands to execute in interactive terminals
#
# Executed last
# Not included in non-interactive terminals, like cron
#

# To interoperate with bash-preexec, detect if it's already sourced and use it's preexec / precmd
# hooks instead of directly setting the PROMPT_COMMAND and DEBUG trap.
# See https://github.com/rcaloras/bash-preexec
# If it hasn't been installed yet that's OK; as of
# https://github.com/rcaloras/bash-preexec/commit/a1bab0c24b it will preserve any existing DEBUG
# and PROMPT_COMMAND settings. We just need to ensure we don't overwrite it.
#
# It's also necessary to preserve this behavior during pgem_reload, which is the cause of most of
# the complexity of this conditional.
# shellcheck disable=SC2154
if "$COMPATIBLE_WITH_PREEXEC" && [[ -n "$__bp_imported" ]]; then
  pg::log "bash-preexec found; not updating PROMPT_COMMAND and DEBUG trap"
  if [[ "$(type __bp_original_debug_trap 2>/dev/null)" != *" _time_command"* ]]; then
    for i in "${!preexec_functions[@]}"; do
      if [[ "${preexec_functions[$i]}" == "_time_command" ]]; then unset "preexec_functions[$i]"; fi
    done
    if "$CAPTURE_COMMAND_TIMES"; then preexec_functions+=(_time_command); fi
  fi

  if [[ "$(type __bp_original_prompt_command 2>/dev/null)" != *" _prompt_command"* ]]; then
    for i in "${!precmd_functions[@]}"; do
      if [[ "${precmd_functions[$i]}" == "_prompt_command" ]]; then unset "precmd_functions[$i]"; fi
    done
    precmd_functions=(_prompt_command "${precmd_functions[@]}")
  fi
else
  # Note this has no effect from pgem_reload, because functions can't overwrite external traps
  "$CAPTURE_COMMAND_TIMES" && trap '_time_command' DEBUG
  PROMPT_COMMAND="_prompt_command"
fi

if "${_PGEM_DEBUG:-false}"; then
  # running _prompt_command directly has the added benefit of setting PS1 before pgem_reload
  # compares environments; otherwise it would report that PS1 had been set to the value of
  # _PRE_PGEM_PS1
  echo "PROMPT_COMMAND took:"
  time _prompt_command
fi
