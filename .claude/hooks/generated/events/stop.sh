#!/usr/bin/env bash
#
# stop.sh
#
# Event:
#   Stop
#
# What this hook does:
#   Runs the same validation the Validate Skills GitHub Actions workflow runs,
#   so the turn fails loudly if CI would fail. The logic lives in the shared
#   script at scripts/validate-all-skills.sh, which CI also calls.
#
# Fast path:
#   Skips silently when the working tree is clean and the branch is not ahead
#   of its upstream. A conversational turn where nothing changed should not
#   pay the cost of running Python validators and npx.
#
# Loop guard:
#   Honors stop_hook_active. If this hook already blocked once in the current
#   stop cycle, the second invocation exits 0 so Claude can actually stop.
#   The user still sees the failure from the first attempt in the transcript.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../lib/common.sh"

HOOK_INPUT="$(read_hook_input)"
readonly HOOK_INPUT

# Loop guard: if Claude already retried because of this hook, let it stop.
if [ "$(hook_json '.stop_hook_active' 'false')" = "true" ]; then
    exit 0
fi

# CLAUDE_PROJECT_DIR is set by Claude Code for hook invocations.
cd "${CLAUDE_PROJECT_DIR:-$SCRIPT_DIR/../../../..}"

# Fast path: nothing to validate if the working tree is clean, the branch is
# not ahead of its upstream, AND no skill files are hidden from CI by an
# external ignore source (user-global gitignore or $GIT_DIR/info/exclude).
#
# Untracked files count as dirty via git status --porcelain. Globally-ignored
# files do NOT show up in porcelain, so a newly created AGENTS.md (ignored by
# the user's global gitignore) would slip past the fast path and cause a CI
# failure that this hook never warned about. has_invisible_skill_files()
# closes that hole by forcing full validation whenever such files exist.
has_invisible_skill_files() {
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        src="$(git check-ignore -v -- "$file" 2>/dev/null || true)"
        src="${src%%:*}"
        if [[ "$src" == /* ]] || [[ "$src" == *".git/info/exclude" ]]; then
            return 0
        fi
    done < <(git ls-files --others --ignored --exclude-standard skills 2>/dev/null)
    return 1
}

if [ -z "$(git status --porcelain 2>/dev/null)" ] \
    && ! has_invisible_skill_files \
    && upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" \
    && ahead_count="$(git rev-list --count "${upstream_ref}..HEAD" 2>/dev/null)" \
    && [ "$ahead_count" = "0" ]; then
    exit 0
fi

# Run the shared validator. On failure, exit 2 with the full output on stderr
# so Claude sees what broke and can fix it on the next turn.
if ! VALIDATION_OUTPUT="$(bash "$PWD/scripts/validate-all-skills.sh" 2>&1)"; then
    {
        echo "Skill validation failed. Fix the errors below before ending the turn."
        echo "This runs the same checks as .github/workflows/validate-skills.yml."
        echo
        printf '%s\n' "$VALIDATION_OUTPUT"
    } >&2
    exit 2
fi

exit 0
