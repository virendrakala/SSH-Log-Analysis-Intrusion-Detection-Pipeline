#!/bin/bash
# timeline.sh
# Task 4 — Hourly threat timeline
#
# Filters "Failed password" entries from clean_log.csv,
# extracts the two-digit hour from each timestamp,
# counts failures per hour, and prints results in
# ascending chronological order (00 → 23).
#
# Usage:
#   bash timeline.sh clean_log.csv

LOGFILE="$1"

# ── Validate argument ────────────────────────────────────────────────────────
if [[ $# -ne 1 ]]; then
    echo "Usage: bash timeline.sh <clean_log_csv>"
    exit 1
fi

if [[ ! -f "$LOGFILE" ]]; then
    echo "Error: file not found — $LOGFILE"
    exit 1
fi

# ── Extract hour and aggregate with awk ──────────────────────────────────────
#
# Timestamp field format:  2026-02-18 09:00:01
# It is the very first comma-separated field in every log line.
#
# awk logic:
#   - FS = ","  so $1 = "2026-02-18 09:00:01"
#   - Trim leading/trailing spaces from $1
#   - split($1, dt, " ")  →  dt[1]="2026-02-18"  dt[2]="09:00:01"
#   - split(dt[2], hms, ":") →  hms[1]="09"
#   - Accumulate in  bucket[hour]++
#
# At END we iterate 0..23 with printf "%02d" to produce zero-padded keys
# that match however awk stored them, ensuring correct ascending order
# without relying on any external sort command.

grep 'Failed password' "$LOGFILE" \
| awk -F',' '
    {
        ts = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", ts)

        # separate date and clock portions
        if (split(ts, dt, " ") == 2) {
            if (split(dt[2], hms, ":") >= 1) {
                hr = hms[1]
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", hr)
                bucket[hr]++
            }
        }
    }
    END {
        # Walk every possible hour 00-23 in strict numeric order
        for (h = 0; h <= 23; h++) {
            key = sprintf("%02d", h)
            if (key in bucket)
                printf "Hour %s: %d failed attempts\n", key, bucket[key]
        }
    }
'
