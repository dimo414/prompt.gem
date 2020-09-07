#!/bin/bash
# 
# Default configuration file
# 
# Specifies defaults for values to be set by the user's local config file,
# and is loaded before that file.  As these values can be overridden by
# the local config file, avoid setting environment variables and the
# like here, instead define values which environment.sh will then use
# after the user's config file has been loaded.
# 

HOST_COLOR=NONE

# sed replacements of the PWD, generally to shorten it for commonly-used paths
HIDE_PATHS=()
[[ -n "$HOME" ]] && HIDE_PATHS+=("s|^${HOME}|~|")

# Callback functions used to construct the window title
TITLE_INFO=(hostname_title)
# Callback functions used to construct the prompt
ENV_INFO=()
# Callback functions invoked when a command has finished
COMMAND_FINISHED_CALLBACKS=()

# Callback variables
DISPLAY_COMMAND_FINISHED_DIALOG=30

# Enable functionality that requires the DEBUG trap; ignored if bash-preexec is detected.
# Note the debug trap is not updated when running pgem_reload, therefore it is neccessary to launch
# a new shell if changing this value.
OWN_DEBUG_TRAP=true

# Command execution times
DISPLAY_COMMAND_TIME_THRESHOLD=5
