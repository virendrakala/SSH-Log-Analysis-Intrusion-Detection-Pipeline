# SSH Log Analysis & Intrusion Detection Pipeline

A four-stage Bash pipeline that ingests a raw `auth.log`, sanitizes it, detects brute-force attackers, and produces a firewall ruleset, port report, and hourly threat timeline.

---

## Pipeline Overview

```
auth.log
    │
    ▼
sanitize.sh  ──►  clean_log.csv
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
      detect.sh    report.sh   timeline.sh
          │            │            │
          ▼            ▼            ▼
 firewall_rules.sh  port table  hourly chart
```

---

## Scripts

| Script | Task | Input | Output |
|---|---|---|---|
| `sanitize.sh` | Clean raw log | `auth.log` | `clean_log.csv` |
| `detect.sh` | Brute-force detector | `clean_log.csv`, `whitelist.txt` | `firewall_rules.sh` |
| `report.sh` | Port attack dashboard | `clean_log.csv` | stdout |
| `timeline.sh` | Hourly threat timeline | `clean_log.csv` | stdout |

---

## Usage

**Step 1 — Sanitize the raw log**
```bash
bash sanitize.sh auth.log
# Output: clean_log.csv
```

**Step 2 — Detect brute-force attackers**
```bash
bash detect.sh clean_log.csv whitelist.txt firewall_rules.sh
# Output: firewall_rules.sh
```

**Step 3 — Port analysis report**
```bash
bash report.sh clean_log.csv
```

**Step 4 — Hourly timeline**
```bash
bash timeline.sh clean_log.csv
```

---

## Sample Outputs

**detect.sh → firewall_rules.sh**
```
iptables -A INPUT -s 203.0.113.47 -j DROP # Blocked after 47 failed attempts
iptables -A INPUT -s 198.51.100.9 -j DROP # Blocked after 31 failed attempts
```

**report.sh**
```
Target Port Analysis
--------------------
Port 22   : 134 attempts
Port 2222 : 23 attempts
Port 8022 : 11 attempts
```

**timeline.sh**
```
Hour 02: 12 failed attempts
Hour 03: 89 failed attempts
Hour 14: 42 failed attempts
Hour 23: 17 failed attempts
```

---

## Tools Used
- `bash` — control flow, argument validation, loops
- `sed` — log sanitization (delete, substitute)
- `awk` — field parsing, aggregation, formatted output
- `grep` — pre-filtering log lines

---

## Files
```
.
├── sanitize.sh       # Task 1 — log cleaner
├── detect.sh         # Task 2 — brute-force detector
├── report.sh         # Task 3 — port analysis
├── timeline.sh       # Task 4 — hourly timeline
├── sample_auth.log   # dummy log for testing
├── whitelist.txt     # trusted IPs (not blocked)
└── README.md
```
