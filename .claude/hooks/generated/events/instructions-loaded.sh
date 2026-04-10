#!/usr/bin/env bash
#
# instructions-loaded.sh
#
# Event:
#   InstructionsLoaded
#
# What this event is for:
#   Runs when a CLAUDE.md file or .claude/rules markdown file is loaded into context.
#
# Why this stub exists:
#   This scaffold creates one script per official Claude Code hook event so the
#   target project has a stable place to add logic later. Leaving the stub in
#   place makes future additive refreshes and event-set updates predictable.
#
# Recommended starting style:
#   Keep sync when you need to enforce policy or inject context. Use async only for passive audit work.
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

