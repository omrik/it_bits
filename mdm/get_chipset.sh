#!/bin/bash
# get_chipset.sh - MDM attribute: graphics chip(s), one per GPU, comma-separated.
# Example output: Apple M2 Pro
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

gpus=$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F": " "/Chipset Model/ { print \$2 }" | paste -sd "," - | sed "s/,/, /g")
result "${gpus:-unknown}"
