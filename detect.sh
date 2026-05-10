#!/bin/bash
# detect.sh
# Task 2 — Brute-force detector
#
# Reads the cleaned log, counts Failed-password events per IP,
# keeps only IPs that crossed the threshold (> 10 attempts),
# removes whitelisted addresses using a manual loop (no grep -f / comm / diff),
# and writes iptables DROP rules to the output file.
#
# Usage:
#   bash detect.sh clean_log.csv whitelist.txt firewall_rules.sh

LOGFILE="$1"
WHITELIST="$2"
OUTFILE="$3"

# ── Validate arguments ───────────────────────────────────────────────────────
if [[ $# -ne 3 ]]; then
    echo "Usage: bash detect.sh <log> <whitelist> <output>"
    exit 1
fi

for f in "$LOGFILE" "$WHITELIST"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: file not found — $f"
        exit 1
    fi
done

# ── Step 1 & 2: Count failures per IP ────────────────────────────────────────
#
# We grep for lines that contain "Failed password", then hand them to awk.
#
# awk breakdown:
#   - FS = ","  → fields are comma-separated after sanitize.sh ran
#   - For every field, strip leading/trailing spaces, then check for "ip="
#   - Split that field on "=" and grab the second element (the actual address)
#   - Accumulate in the associative array  hits[addr]++
#   - At END, print only entries whose count is strictly > 10
#
# The output lines look like:   <count> <ip>

THRESHOLD=10

while IFS=" " read -r cnt ip; do
    # ── Step 3: Whitelist check (manual loop — no grep -f / comm / diff) ────
    #
    # We read the whitelist file one line at a time inside a while-loop.
    # A flag variable tracks whether the current suspect IP was found.
    # If it was found we skip it; otherwise we write the firewall rule.

    blocked=1          # assume we should block until proven otherwise

    while IFS= read -r trusted || [[ -n "$trusted" ]]; do
        # strip any accidental whitespace from the whitelist entry
        trusted="$(echo "$trusted" | tr -d '[:space:]')"
        [[ -z "$trusted" ]] && continue       # skip blank lines

        if [[ "$ip" == "$trusted" ]]; then
            blocked=0   # found in whitelist → do NOT block
            break
        fi
    done < "$WHITELIST"

    # ── Step 4: Emit firewall rule for non-whitelisted IPs ──────────────────
    if [[ "$blocked" -eq 1 ]]; then
        echo "iptables -A INPUT -s $ip -j DROP # Blocked after $cnt failed attempts" >> "$OUTFILE"
    fi

done < <(
    grep 'Failed password' "$LOGFILE" \
    | awk -F',' -v thresh="$THRESHOLD" '
        {
            for (i = 1; i <= NF; i++) {
                field = $i
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", field)
                if (field ~ /^ip=/) {
                    split(field, kv, "=")
                    addr = kv[2]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", addr)
                    hits[addr]++
                }
            }
        }
        END {
            for (addr in hits)
                if (hits[addr] > thresh)
                    print hits[addr], addr
        }
    '
)

echo "Detection complete → $OUTFILE"
