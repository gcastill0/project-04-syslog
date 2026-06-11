#!/usr/bin/env bash
# Replay syslog sample files to a local UDP 514 listener.
# Timestamps in each message are replaced with the current date/time before sending.
#
# Usage:
#   ./replay_syslog.sh [OPTIONS] <file> [file ...]
#
# Options:
#   -h HOST     Destination host   (default: 127.0.0.1)
#   -p PORT     Destination port   (default: 514)
#   -d DELAY    Delay between msgs in seconds, decimals ok  (default: 0.05)
#   -r          Randomise message order before replaying
#   -l          Loop forever (restart from beginning when done)
#   --help      Show this help
#
# Examples:
#   bash replay_syslog.sh samples/cisco_syslog.log
#   bash replay_syslog.sh -d 0.1 samples/cisco_syslog.log samples/fortigate_syslog.log
#   bash replay_syslog.sh -h 192.168.1.100 -r -l samples/cisco_syslog.log

set -euo pipefail

HOST="127.0.0.1"
PORT=514
DELAY=0.05
RANDOMISE=false
LOOP=false
FILES=()

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \?//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h) HOST="$2";      shift 2 ;;
        -p) PORT="$2";      shift 2 ;;
        -d) DELAY="$2";     shift 2 ;;
        -r) RANDOMISE=true; shift   ;;
        -l) LOOP=true;      shift   ;;
        --help) usage ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *)  FILES+=("$1");  shift   ;;
    esac
done

[[ ${#FILES[@]} -eq 0 ]] && { echo "Error: no input files specified."; echo "Run with --help for usage."; exit 1; }


for cmd in nc python3; do
    command -v "$cmd" &>/dev/null || { echo "Error: '$cmd' not found in PATH."; exit 1; }
done

# nc must support UDP (-u); verify
nc -h 2>&1 | grep -q "\-u" || { echo "Warning: nc may not support -u flag on this system."; }


send_udp() {
    printf '%s\n' "$1" | nc -u -w0 "$HOST" "$PORT" 2>/dev/null || true
}


#   1. RFC 5424 ISO-8601   e.g. 2024-03-15T08:00:01Z  (FortiGate)
#   2. BSD syslog          e.g. Mar 15 08:00:01        (Cisco ASA / IOS)
#   3. date= / time= pairs e.g. date=2024-03-15 time=08:00:01  (FortiGate KV)
replace_timestamp() {
    local line="$1"
    local now_iso
    local now_bsd
    local now_date
    local now_time
    now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    now_bsd=$(date -u +"%-b %e %H:%M:%S")   # e.g. "Jun 11 14:05:03"
    now_date=$(date -u +"%Y-%m-%d")
    now_time=$(date -u +"%H:%M:%S")

    # Replace ISO-8601 timestamp in RFC 5424 header (position 2)
    line=$(echo "$line" | sed -E "s|[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z|${now_iso}|g")

    # Replace BSD syslog timestamp (Jan/Feb/.../Dec DD HH:MM:SS)
    line=$(echo "$line" | sed -E "s|(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) +[0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}|${now_bsd}|g")

    # Replace FortiGate key=value date/time fields
    line=$(echo "$line" | sed -E "s|date=[0-9]{4}-[0-9]{2}-[0-9]{2}|date=${now_date}|g")
    line=$(echo "$line" | sed -E "s|time=[0-9]{2}:[0-9]{2}:[0-9]{2}|time=${now_time}|g")

    # Replace eventtime= (unix epoch) with current epoch
    local now_epoch
    now_epoch=$(date -u +"%s")
    line=$(echo "$line" | sed -E "s|eventtime=[0-9]+|eventtime=${now_epoch}|g")

    echo "$line"
}


declare -a ALL_LINES=()
for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || { echo "Error: file not found: $f"; exit 1; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        ALL_LINES+=("$line")
    done < "$f"
done

TOTAL=${#ALL_LINES[@]}
echo "Loaded ${TOTAL} messages from ${#FILES[@]} file(s)"
echo "Sending to ${HOST}:${PORT} (UDP) — delay ${DELAY}s between messages"
echo "Press Ctrl+C to stop."
echo "──────────────────────────────────────────"


if $RANDOMISE; then
    echo "Randomising message order..."
    # Fisher-Yates via python3 (bash arrays can't shuffle portably)
    mapfile -t ALL_LINES < <(python3 -c "
import sys, random
lines = sys.stdin.read().splitlines()
random.shuffle(lines)
print('\n'.join(lines))
" <<< "$(printf '%s\n' "${ALL_LINES[@]}")")
fi


run_once() {
    local count=0
    for line in "${ALL_LINES[@]}"; do
        count=$((count + 1))
        local stamped
        stamped=$(replace_timestamp "$line")
        send_udp "$stamped"
        printf "\r[%d/%d] Sent" "$count" "$TOTAL"
        sleep "$DELAY"
    done
    printf "\n"
}

if $LOOP; then
    round=1
    while true; do
        echo "── Round ${round} ──"
        run_once
        round=$((round + 1))
    done
else
    run_once
    echo "Done. ${TOTAL} messages sent."
fi
