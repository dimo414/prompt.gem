#!/bin/bash
#
# Bash aliases
#

# http://stackoverflow.com/q/8996820/113632
# If this still proves insufficient, it might be simpler to outsource to Python
! command -v md5sum >& /dev/null && command -v md5 >& /dev/null && alias md5sum=md5 || true