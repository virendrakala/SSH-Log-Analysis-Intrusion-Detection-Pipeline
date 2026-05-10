#!/bin/bash
# sanitize.sh
# Task 1 — Cleans the raw auth.log file
#
# What it does:
#   1. Drops every line that contains [CORRUPT-DATA]
#   2. Replaces user=root and user=admin with user=SYS_ADMIN
#   3. Converts all pipe '|' separators into commas ','
#
# Usage:
#   bash sanitize.sh auth.log

INPUT="${1}"
OUTPUT="clean_log.csv"

# ── Validate input ──────────────────────────────────────────────────────────
if [[ $# -ne 1 ]]; then
    echo "Usage: bash sanitize.sh <auth_log>"
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: file not found — $INPUT"
    exit 1
fi

# ── Three-stage sed pipeline ─────────────────────────────────────────────────
#
# Stage 1:  /\[CORRUPT-DATA\]/d
#   The 'd' command deletes the whole line when the pattern matches.
#   Square brackets are regex metacharacters, so we escape them (\[ \]).
#
# Stage 2:  s/user=root/user=SYS_ADMIN/g
#           s/user=admin/user=SYS_ADMIN/g
#   Two explicit substitutions — one for root, one for admin.
#   The /g flag replaces every occurrence on a line, not just the first.
#
# Stage 3:  s/|/,/g
#   Replaces every pipe with a comma, enforcing a uniform CSV layout.

sed '/\[CORRUPT-DATA\]/d' "$INPUT"       \
    | sed 's/user=root/user=SYS_ADMIN/g; s/user=admin/user=SYS_ADMIN/g' \
    | sed 's/|/,/g'                       \
    > "$OUTPUT"

echo "Sanitization complete → $OUTPUT"
