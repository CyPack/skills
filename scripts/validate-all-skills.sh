#!/usr/bin/env bash
#
# validate-all-skills.sh
#
# Run the same validation that the Validate Skills GitHub Actions workflow
# runs, so anything that would break CI gets caught locally first.
#
# This script is the shared source of truth between:
#   1. .github/workflows/validate-skills.yml
#   2. .claude/hooks/generated/events/stop.sh
#
# If you change a step here, both callers pick it up.
#
# Steps:
#   1. For every skills/<name>/ that has a SKILL.md, run validate.py and
#      test_skill.py.
#   2. Confirm skills.sh discovery still works via `npx --yes skills add .
#      --list`.
#
# Usage:
#   bash scripts/validate-all-skills.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

while IFS= read -r skill; do
    echo "Validating ${skill}"
    python3 "${skill}/scripts/validate.py" "${skill}"
    python3 "${skill}/scripts/test_skill.py" "${skill}"
done < <(find skills -mindepth 1 -maxdepth 1 -type d -exec test -f "{}/SKILL.md" ';' -print | LC_ALL=C sort)

echo "Checking skills.sh discovery"
npx --yes skills add . --list
