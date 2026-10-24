#!/bin/bash
# implement-feature/context-usage.sh
# Prints how many tokens this session's context currently holds, read from the session transcript,
# so the skill can tell the user when /clear would help. The model cannot see this number on its own.
#
# Usage: context-usage.sh [threshold]      default threshold 200000
# Exit:  0 = below threshold, 1 = at or above threshold, 2 = could not tell (skip the check)
#
# Context size = input + cache-creation + cache-read tokens of the most recent main-session reply.

THRESHOLD="${1:-200000}"
DIR="$HOME/.claude/projects/$(pwd | sed 's/[^A-Za-z0-9]/-/g')"

if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -f "$DIR/$CLAUDE_CODE_SESSION_ID.jsonl" ]; then
    FILE="$DIR/$CLAUDE_CODE_SESSION_ID.jsonl"
else
    # No session id: fall back to the most recently written transcript for this directory.
    FILE=$(ls -t "$DIR"/*.jsonl 2>/dev/null | head -1)
fi

if [ -z "$FILE" ] || ! command -v python3 >/dev/null 2>&1; then
    echo "CONTEXT  unknown - no transcript or no python3. Skip the context check."
    exit 2
fi

TOKENS=$(python3 -I - "$FILE" <<'EOF'
import json, sys
last = None
with open(sys.argv[1], errors="ignore") as f:
    for line in f:
        if '"usage"' not in line:
            continue
        try:
            o = json.loads(line)
        except ValueError:
            continue
        if o.get("isSidechain"):
            continue
        u = (o.get("message") or {}).get("usage")
        if isinstance(u, dict):
            last = u
if last:
    print(sum(last.get(k) or 0 for k in
              ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")))
EOF
)

if [ -z "$TOKENS" ]; then
    echo "CONTEXT  unknown - no usage recorded yet. Skip the context check."
    exit 2
fi

K=$((TOKENS / 1000))
if [ "$TOKENS" -ge "$THRESHOLD" ]; then
    echo "CONTEXT  ${K}k tokens - over $((THRESHOLD / 1000))k. Add to the report: use /clear to reduce token usage between slices."
    exit 1
fi
echo "CONTEXT  ${K}k tokens - below $((THRESHOLD / 1000))k. No action."
exit 0
