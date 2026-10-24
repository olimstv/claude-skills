#!/bin/bash
# implement-feature/slice-index.sh
# Emits a compact index of a feature's slices and validates the Status/Complexity/MCP/Blocked-by
# contract, so Phase 1 does not have to read every slice body to learn the shape of the work.
#
# Usage: slice-index.sh <feature-dir>      e.g. slice-index.sh .scratch/trainer-detail-report
# Exit:  0 = contract holds, 1 = contract violated (details in output), 2 = bad usage
#
# Written for bash 3.2 (the macOS system bash): no associative arrays, and slice numbers are
# forced to base 10 so that 08 and 09 are not read as invalid octal.

set -uo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then
    echo "usage: slice-index.sh <feature-dir>" >&2
    exit 2
fi
DIR="${DIR%/}"
SLICE_DIR="$DIR/slices"

if [ ! -d "$SLICE_DIR" ]; then
    echo "error: no slices directory at $SLICE_DIR" >&2
    exit 2
fi

shopt -s nullglob
FILES=("$SLICE_DIR"/*.md)
if [ ${#FILES[@]} -eq 0 ]; then
    echo "error: no slice files in $SLICE_DIR" >&2
    exit 2
fi

ISSUES=()
IDX=()          # slice numbers present, in file order
TITLE=(); STATUS=(); CPLX=(); MCP=(); BLOCKED=(); FILEOF=()

# field <file> <label>  ->  value after "Label:" on its own line
field() {
    sed -n "s/^$2:[[:space:]]*//p" "$1" | head -1 | tr -d '\r'
}

for f in "${FILES[@]}"; do
    base=$(basename "$f" .md)
    num="${base%%-*}"
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        ISSUES+=("$base: filename does not start with a slice number")
        continue
    fi
    i=$((10#$num))

    IDX+=("$i")
    FILEOF[$i]="$f"
    TITLE[$i]="${base#*-}"
    STATUS[$i]=$(field "$f" "Status")
    CPLX[$i]=$(field "$f" "Complexity")
    # MCP: "none" or comma-separated server names. Missing on plans written before the field
    # existed - not a violation; shown as "?" and decided from the slice body (delegation.md).
    MCP[$i]=$(field "$f" "MCP" | tr -d ' ')

    # "Blocked by" is a section heading; take the first non-empty line under it
    BLOCKED[$i]=$(awk '/^##[[:space:]]*Blocked by/{f=1;next} f&&NF{print;exit}' "$f" | tr -d '\r')

    case "${STATUS[$i]}" in
        pending|in-progress|done) ;;
        "") ISSUES+=("$num: missing Status line") ;;
        *)  ISSUES+=("$num: Status is '${STATUS[$i]}' - must be pending, in-progress, or done") ;;
    esac
    # Complexity: "5 (design 2, scope 1, tests 1, hazards 1)" - a 0-8 total, then a breakdown that
    # must sum to it. Legacy low/medium/high plans are still accepted and shown as-is.
    raw="${CPLX[$i]}"
    case "$raw" in
        low|medium|high) ;;
        "") ISSUES+=("$num: missing Complexity line - treat this slice as 4") ;;
        *)
            total="${raw%%[!0-9]*}"
            if [ -z "$total" ] || [ "$total" -gt 8 ]; then
                ISSUES+=("$num: Complexity is '$raw' - must be a 0-8 score, e.g. '5 (design 2, scope 1, tests 1, hazards 1)'")
            else
                CPLX[$i]="$((10#$total))"
                case "$raw" in
                    *"("*)
                        parts=$(echo "${raw#*(}" | grep -oE '[0-9]+')
                        sum=0; n=0
                        for p in $parts; do sum=$((sum + 10#$p)); n=$((n + 1)); done
                        if [ "$n" -ne 4 ] || [ "$sum" -ne "$((10#$total))" ]; then
                            ISSUES+=("$num: Complexity breakdown in '$raw' does not give four scores summing to $total")
                        fi
                        ;;
                esac
            fi
            ;;
    esac
done

if [ ${#IDX[@]} -eq 0 ]; then
    echo "error: no parseable slices in $SLICE_DIR" >&2
    exit 2
fi

IDX=($(printf '%s\n' "${IDX[@]}" | sort -n -u))

# deps_of <index>  ->  dependency indexes, one per line
deps_of() {
    echo "${BLOCKED[$1]:-}" | grep -oE '[0-9]+' | while read -r d; do echo $((10#$d)); done
}

pad() { printf '%02d' "$1"; }

for i in "${IDX[@]}"; do
    for d in $(deps_of "$i"); do
        if [ -z "${STATUS[$d]:-}" ]; then
            ISSUES+=("$(pad "$i"): Blocked by $(pad "$d") - no such slice")
        elif [ "$d" = "$i" ]; then
            ISSUES+=("$(pad "$i"): Blocked by itself")
        elif [ "${STATUS[$i]}" = "done" ] && [ "${STATUS[$d]}" != "done" ]; then
            ISSUES+=("$(pad "$i"): marked done but depends on $(pad "$d") which is ${STATUS[$d]}")
        fi
    done
done

INPROG=(); PENDING=(); NDONE=0
for i in "${IDX[@]}"; do
    case "${STATUS[$i]}" in
        in-progress) INPROG+=("$i") ;;
        pending)     PENDING+=("$i") ;;
        done)        NDONE=$((NDONE + 1)) ;;
    esac
done
if [ ${#INPROG[@]} -gt 1 ]; then
    padded=$(for i in "${INPROG[@]}"; do printf '%02d ' "$i"; done)
    ISSUES+=("${#INPROG[@]} slices are in-progress (${padded% }) - only one is allowed")
fi

# ---- output ----
echo "FEATURE  $(basename "$DIR")"
echo "SLICES   ${#IDX[@]} total - $NDONE done, ${#INPROG[@]} in-progress, ${#PENDING[@]} pending"
if [ -f "$DIR/PROGRESS.md" ]; then
    echo "PROGRESS $DIR/PROGRESS.md exists - read its header only (see full-mode.md Phase 1)"
fi
echo ""
printf '%-4s %-34s %-12s %-7s %-16s %s\n' "NUM" "TITLE" "STATUS" "CPLX" "MCP" "BLOCKED BY"
for i in "${IDX[@]}"; do
    b=$(deps_of "$i" | while read -r d; do printf '%02d\n' "$d"; done | paste -sd, -)
    printf '%02d   %-34s %-12s %-7s %-16s %s\n' \
        "$i" "${TITLE[$i]:0:34}" "${STATUS[$i]:-?}" "${CPLX[$i]:-?}" "${MCP[$i]:-?}" "${b:-none}"
done
echo ""

if [ ${#INPROG[@]} -ge 1 ]; then
    i="${INPROG[0]}"
    printf 'NEXT     %02d %s - IN PROGRESS. A previous session stopped part-way.\n' "$i" "${TITLE[$i]}"
    echo "         Read ${FILEOF[$i]}, find what actually landed, re-run the tests, then resume."
elif [ ${#PENDING[@]} -ge 1 ]; then
    found=0
    for i in "${PENDING[@]}"; do
        ready=1
        for d in $(deps_of "$i"); do
            [ "${STATUS[$d]:-}" = "done" ] || ready=0
        done
        if [ "$ready" = "1" ]; then
            printf 'NEXT     %02d %s (complexity %s, mcp %s)\n' "$i" "${TITLE[$i]}" "${CPLX[$i]:-4}" "${MCP[$i]:-?}"
            found=1
            break
        fi
    done
    if [ "$found" = "0" ]; then
        ISSUES+=("no pending slice has all its dependencies done - check for a dependency cycle")
    fi
else
    echo "NEXT     none - all slices done. Read reference/finish.md for Phase 3 end-to-end verification."
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo ""
    echo "CONTRACT VIOLATIONS - resolve these before implementing:"
    printf '  ! %s\n' "${ISSUES[@]}"
    exit 1
fi
exit 0
