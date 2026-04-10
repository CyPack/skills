#!/usr/bin/env bash
#
# common.sh
#
# Shared helper functions for generated Claude Code hook scripts.
#
# Keep this file small and boring. The goal is to make each event stub easier
# to extend, not to hide important behavior.
#

set -euo pipefail

read_hook_input() {
    # Claude Code passes JSON to command hooks on stdin.
    # Read the whole payload so each stub can inspect it later.
    cat
}

hook_json() {
    # Read a value from the hook JSON payload with jq.
    #
    # Arguments:
    #   1. jq filter
    #   2. optional fallback string
    local filter="$1"
    local fallback="${2:-}"

    if ! command -v jq >/dev/null 2>&1; then
        if [ -n "$fallback" ]; then
            printf '%s\n' "$fallback"
            return 0
        fi
        echo "jq is required to parse hook JSON." >&2
        return 1
    fi

    if [ -n "$fallback" ]; then
        printf '%s' "$HOOK_INPUT" | jq -er "$filter" 2>/dev/null || printf '%s\n' "$fallback"
    else
        printf '%s' "$HOOK_INPUT" | jq -er "$filter"
    fi
}

write_system_message() {
    # Return a systemMessage payload Claude Code can consume on the next turn.
    local message="$1"
    jq -n --arg message "$message" '{systemMessage: $message}'
}

write_additional_context() {
    # Return additionalContext text for the next Claude turn.
    local message="$1"
    jq -n --arg message "$message" '{additionalContext: $message}'
}
