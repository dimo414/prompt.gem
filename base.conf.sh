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

HIDE_PATHS=("s|^${HOME}|~|")
TITLE_INFO=(hostname_title)
ENV_INFO=()

CAPTURE_COMMAND_TIMES=true
DISPLAY_COMMAND_TIME_THRESHOLD=5
COMMAND_FINISHED_CALLBACKS=()

ENABLE_CACHED_COMMANDS=true
CACHE_DIR=/tmp/promt.gem.cache

# Callback variables
DISPLAY_COMMAND_FINISHED_DIALOG=30
