#!/bin/bash
# code-review/prepare.sh
# Prepares metadata for code review: review range, branch info, ClickUp URLs, file changes,
# git state validation. Outputs structured JSON to reduce token usage and git command overhead.
#
# Usage:
#   prepare.sh                     auto-detect the base branch and review this branch's own work
#   prepare.sh --base origin/beta  review against an explicit base ref
#   prepare.sh --last 5            review the last 5 commits on HEAD (use when on a base branch)
#   prepare.sh --since <sha>       review every commit after <sha>, up to HEAD
#   prepare.sh --range <a>..<b>    review an explicit commit range
#
# Range semantics, and why they matter:
#   - The DIFF is taken from the merge-base of the base ref and HEAD. That is what excludes work
#     merged IN from master/production: once you merge a base branch into your branch, the
#     merge-base moves forward to that commit, so the merged content falls out of the diff.
#   - The COMMIT LIST uses two-dot range plus --no-merges, so it contains only commits authored
#     on this branch. Three-dot (A...HEAD) on git log is a SYMMETRIC DIFFERENCE and wrongly
#     includes commits that are only on the base branch.

set -uo pipefail

RED='\033[0;31m'
NC='\033[0m'

BASE_REF=""
MODE="auto"
LAST_N=""
SINCE_SHA=""
EXPLICIT_RANGE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --base)  BASE_REF="${2:-}"; MODE="base";  shift 2 ;;
        --last)  LAST_N="${2:-}";   MODE="last";  shift 2 ;;
        --since) SINCE_SHA="${2:-}"; MODE="since"; shift 2 ;;
        --range) EXPLICIT_RANGE="${2:-}"; MODE="range"; shift 2 ;;
        *) echo -e "${RED}Error: unknown argument '$1'${NC}" >&2; exit 2 ;;
    esac
done

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
    echo -e "${RED}Error: Not in a git repository${NC}" >&2
    exit 1
fi

WARNINGS=()
CANDIDATES="origin/master origin/production origin/beta origin/main master production beta main"

# ---------------------------------------------------------------------------
# Resolve the review range
# ---------------------------------------------------------------------------
RANGE_START=""      # exclusive: the commit the review starts AFTER
RANGE_DESC=""

case "$MODE" in
    last)
        if ! [[ "$LAST_N" =~ ^[0-9]+$ ]] || [ "$LAST_N" -lt 1 ]; then
            echo -e "${RED}Error: --last needs a positive integer${NC}" >&2; exit 2
        fi
        RANGE_START=$(git rev-parse --verify -q "HEAD~$LAST_N^{commit}" 2>/dev/null || echo "")
        if [ -z "$RANGE_START" ]; then
            TOTAL=$(git rev-list --count HEAD 2>/dev/null || echo 0)
            echo -e "${RED}Error: --last $LAST_N but this branch has only $TOTAL commits${NC}" >&2
            exit 2
        fi
        BASE_REF="HEAD~$LAST_N"
        RANGE_DESC="last $LAST_N commits on $BRANCH"
        ;;
    since)
        RANGE_START=$(git rev-parse --verify -q "${SINCE_SHA}^{commit}" 2>/dev/null || echo "")
        if [ -z "$RANGE_START" ]; then
            echo -e "${RED}Error: '$SINCE_SHA' is not a commit in this repository${NC}" >&2; exit 2
        fi
        if ! git merge-base --is-ancestor "$RANGE_START" HEAD 2>/dev/null; then
            echo -e "${RED}Error: '$SINCE_SHA' is not an ancestor of HEAD${NC}" >&2; exit 2
        fi
        BASE_REF="$SINCE_SHA"
        RANGE_DESC="commits after $(git rev-parse --short "$RANGE_START"), up to HEAD"
        ;;
    range)
        RANGE_START="${EXPLICIT_RANGE%%..*}"
        RANGE_START=$(git rev-parse --verify -q "${RANGE_START}^{commit}" 2>/dev/null || echo "")
        if [ -z "$RANGE_START" ]; then
            echo -e "${RED}Error: cannot resolve range '$EXPLICIT_RANGE'${NC}" >&2; exit 2
        fi
        BASE_REF="${EXPLICIT_RANGE%%..*}"
        RANGE_DESC="explicit range $EXPLICIT_RANGE"
        ;;
    base)
        if ! git rev-parse --verify -q "$BASE_REF" >/dev/null 2>&1; then
            echo -e "${RED}Error: base ref '$BASE_REF' not found${NC}" >&2; exit 2
        fi
        RANGE_START=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || echo "")
        RANGE_DESC="$BRANCH since it diverged from $BASE_REF"
        ;;
    auto)
        # Pick the candidate base whose merge-base with HEAD is the MOST RECENT, i.e. the
        # closest ancestor. This is what makes a re-merge of master behave correctly: after
        # merging master in, its merge-base moves forward and master wins, so its content is
        # excluded from the diff.
        BEST_TS=-1
        for cand in $CANDIDATES; do
            git rev-parse --verify -q "$cand" >/dev/null 2>&1 || continue
            # Never review a branch against itself.
            [ "$cand" = "$BRANCH" ] && continue
            [ "$cand" = "origin/$BRANCH" ] && continue
            mb=$(git merge-base "$cand" HEAD 2>/dev/null) || continue
            # If HEAD is already fully contained in the candidate, there is nothing to review
            # against it - this is the "I merged my branch back into master" case.
            git merge-base --is-ancestor HEAD "$cand" 2>/dev/null && continue
            ts=$(git show -s --format=%ct "$mb" 2>/dev/null || echo 0)
            if [ "$ts" -gt "$BEST_TS" ]; then
                BEST_TS="$ts"; BASE_REF="$cand"; RANGE_START="$mb"
            fi
        done

        if [ -z "$BASE_REF" ]; then
            echo -e "${RED}Error: could not determine a base branch to review against.${NC}" >&2
            echo "This usually means HEAD is a base branch, or its work is already merged into one." >&2
            echo "Say which range you want, e.g. --last 5, --since <sha>, or --base origin/production." >&2
            exit 1
        fi
        RANGE_DESC="$BRANCH since it diverged from $BASE_REF"

        for b in master production beta main; do
            if [ "$BRANCH" = "$b" ]; then
                WARNINGS+=("HEAD is the base branch '$b'; reviewing against $BASE_REF. If you meant a specific set of commits, re-run with --last N or --since <sha>.")
            fi
        done
        ;;
esac

if [ -z "$RANGE_START" ]; then
    echo -e "${RED}Error: could not resolve the start of the review range${NC}" >&2
    exit 1
fi

# Warn when a local base branch is behind its remote - a stale base silently widens the review.
for b in master production beta main; do
    if [ "$BASE_REF" = "$b" ] && git rev-parse --verify -q "origin/$b" >/dev/null 2>&1; then
        behind=$(git rev-list --count "$b..origin/$b" 2>/dev/null || echo 0)
        [ "$behind" -gt 0 ] && WARNINGS+=("Local '$b' is $behind commits behind origin/$b. Run git fetch, or pass --base origin/$b.")
    fi
done

# ---------------------------------------------------------------------------
# Gather metadata over the resolved range
# ---------------------------------------------------------------------------
TASK_ID=""
if [[ "$BRANCH" =~ ^dev/ ]]; then
    TASK_ID=$(echo "$BRANCH" | grep -oE '[a-z0-9]+$' || echo "")
fi

WORKING_TREE_CLEAN=0
DIRTY_FILES=$(git status --porcelain 2>/dev/null | grep -v '\.claude/commands/code-review' || true)
[ -n "$DIRTY_FILES" ] && WORKING_TREE_CLEAN=1

REMOTE_TRACKED=0
git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 && REMOTE_TRACKED=1

# Commits authored on this branch only: two-dot, merges excluded.
COMMITS_ARRAY=$(git log --no-merges "$RANGE_START..HEAD" --oneline 2>/dev/null \
    | jq -R -s 'split("\n") | map(select(length > 0))')

# Merges present in the range. Their content is other people's already-reviewed work; report
# them so the reviewer knows what was pulled in rather than silently reviewing it.
MERGES_ARRAY=$(git log --merges "$RANGE_START..HEAD" --oneline 2>/dev/null \
    | jq -R -s 'split("\n") | map(select(length > 0))')

CLICKUP_URLS=$(git log --no-merges "$RANGE_START..HEAD" --pretty=format:%b%s 2>/dev/null \
    | grep -oE 'https://app.clickup.com/t/[a-z0-9]+' | sort -u)
if [ -n "$CLICKUP_URLS" ]; then
    CLICKUP_URLS_ARRAY=$(echo "$CLICKUP_URLS" | jq -R . | jq -s .)
else
    CLICKUP_URLS_ARRAY="[]"
fi

CHANGED_FILES_ARRAY=$(git diff "$RANGE_START" HEAD --name-only 2>/dev/null | jq -R . | jq -s . || echo "[]")
FILE_COUNT=$(git diff "$RANGE_START" HEAD --name-only 2>/dev/null | wc -l | tr -d ' ')
TOTAL_CHANGES=$(git diff "$RANGE_START" HEAD --shortstat 2>/dev/null \
    | grep -oE '[0-9]+ (insertion|deletion|file changed)' | tr '\n' ',' | sed 's/,$//')
[ -z "$TOTAL_CHANGES" ] && TOTAL_CHANGES="No changes"

WARNINGS_ARRAY="[]"
if [ ${#WARNINGS[@]} -gt 0 ]; then
    WARNINGS_ARRAY=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
fi

cat <<EOF
{
  "branch": "$BRANCH",
  "base_branch": "$BASE_REF",
  "range_start": "$(git rev-parse --short "$RANGE_START")",
  "range_description": "$RANGE_DESC",
  "diff_command": "git diff $(git rev-parse --short "$RANGE_START") HEAD",
  "task_id": "$TASK_ID",
  "working_tree_clean": $WORKING_TREE_CLEAN,
  "remote_tracked": $REMOTE_TRACKED,
  "commits": $COMMITS_ARRAY,
  "merge_commits_in_range": $MERGES_ARRAY,
  "clickup_urls": $CLICKUP_URLS_ARRAY,
  "changed_files": $CHANGED_FILES_ARRAY,
  "file_count": $FILE_COUNT,
  "total_changes": "$TOTAL_CHANGES",
  "warnings": $WARNINGS_ARRAY
}
EOF
