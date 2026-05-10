#!/bin/bash
# report.sh
# Task 3 — Target Port Analysis dashboard
#
# Reads clean_log.csv, isolates every "Failed password" line,
# counts how many times each port was targeted, and prints a
# formatted table to stdout.
#
# Usage:
#   bash report.sh clean_log.csv

LOGFILE="$1"

# ── Validate argument ────────────────────────────────────────────────────────
if [[ $# -ne 1 ]]; then
    echo "Usage: bash report.sh <clean_log_csv>"
    exit 1
fi

if [[ ! -f "$LOGFILE" ]]; then
    echo "Error: file not found — $LOGFILE"
    exit 1
fi

# ── Print header ─────────────────────────────────────────────────────────────
printf "Target Port Analysis\n"
printf -- "--------------------\n"

# ── Count attempts per port with awk ─────────────────────────────────────────
#
# Only "Failed password" lines are passed to awk (via grep pre-filter).
#
# awk logic:
#   - Split each CSV line on ","
#   - Trim whitespace from every field
#   - When a field starts with "port=", extract the number after "="
#   - Track totals in the array  tally[port]++
#   - At END, sort port numbers numerically and print the formatted table

grep 'Failed password' "$LOGFILE" \
| awk -F',' '
    {
        for (i = 1; i <= NF; i++) {
            f = $i
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", f)
            if (f ~ /^port=/) {
                split(f, kv, "=")
                p = kv[2]
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)
                tally[p]++
            }
        }
    }
    END {
        for (p in tally)
            printf "%d %s\n", tally[p], p
    }
' \
| sort -k2 -n \
| awk '{ printf "Port %s : %d attempts\n", $2, $1 }'
