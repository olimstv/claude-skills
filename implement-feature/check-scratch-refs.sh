#!/bin/bash
# implement-feature/check-scratch-refs.sh
# Fails if any permanent file or commit message references an ephemeral planning directory.
# .scratch/ is deleted at the user's discretion, so every pointer into it is a broken link
# waiting to happen. Run in Phase 3, before declaring the feature done.
#
# Usage: check-scratch-refs.sh [base-ref]     base-ref defaults to origin/master
# Exit:  0 = clean, 1 = references found

set -uo pipefail

BASE="${1:-origin/master}"
PATTERN='\.scratch|scratchpad/'
FOUND=0

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: not in a git repository" >&2
    exit 2
fi

echo "Checking for references to ephemeral planning directories"
echo "=========================================================="
echo ""

# 1. Tracked files. .scratch/ is gitignored so it is already excluded, but exclude it
#    explicitly in case a repo tracks it, and skip the skill files that legitimately
#    describe the convention.
echo -n "Tracked files: "
# CLAUDE.md files and .claude/ state the convention itself, so they name the directory
# legitimately. Anything else that genuinely needs to describe the rule goes here too.
HITS=$(git grep -n -I -E "$PATTERN" -- \
        ':(exclude).scratch/**' \
        ':(exclude).claude/**' \
        ':(exclude)CLAUDE.md' \
        ':(exclude)**/CLAUDE.md' \
        ':(exclude).gitignore' \
        2>/dev/null || true)
if [ -n "$HITS" ]; then
    echo "REFERENCES FOUND"
    echo "$HITS" | sed 's/^/  /'
    FOUND=1
else
    echo "clean"
fi

# 2. Untracked, non-ignored files - new docs the feature added but has not committed yet
echo -n "Untracked files: "
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -v '^\.claude/' || true)
UHITS=""
if [ -n "$UNTRACKED" ]; then
    UHITS=$(echo "$UNTRACKED" | tr '\n' '\0' | xargs -0 grep -n -I -E "$PATTERN" 2>/dev/null || true)
fi
if [ -n "$UHITS" ]; then
    echo "REFERENCES FOUND"
    echo "$UHITS" | sed 's/^/  /'
    FOUND=1
else
    echo "clean"
fi

# 3. Commit messages on this branch
echo -n "Commit messages: "
if git rev-parse --verify -q "$BASE" >/dev/null 2>&1; then
    MB=$(git merge-base "$BASE" HEAD 2>/dev/null || echo "")
    CHITS=""
    if [ -n "$MB" ]; then
        CHITS=$(git log --no-merges "$MB..HEAD" --format='%h %s%n%b' 2>/dev/null \
                | grep -n -E "$PATTERN" || true)
    fi
    if [ -n "$CHITS" ]; then
        echo "REFERENCES FOUND"
        echo "$CHITS" | sed 's/^/  /'
        FOUND=1
    else
        echo "clean"
    fi
else
    echo "skipped - base ref '$BASE' not found"
fi

echo ""
if [ "$FOUND" = "1" ]; then
    echo "FAIL: permanent content points into an ephemeral directory."
    echo "Copy the substance across into the permanent file and delete the pointer."
    echo "Do not resolve this by leaving the path and hoping the directory survives."
    exit 1
fi

echo "PASS: nothing permanent references .scratch/ or scratchpad/."
exit 0
