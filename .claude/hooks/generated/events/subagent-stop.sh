#!/usr/bin/env bash
#
# subagent-stop.sh
#
# Event:
#   SubagentStop
#
# What this event is for:
#   Runs when a subagent finishes.
#
# Why this stub exists:
#   This scaffold creates one script per official Claude Code hook event so the
#   target project has a stable place to add logic later. Leaving the stub in
#   place makes future additive refreshes and event-set updates predictable.
#
# Recommended starting style:
#   Use sync for completion checks. Use async for logging or notifications.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../lib/common.sh"

HOOK_INPUT="$(read_hook_input)"
readonly HOOK_INPUT

# This default scaffold does nothing yet.
# Add project-specific logic below after you decide whether this event should
# block Claude, observe work in the background, or stay as an empty placeholder.

exit 0

