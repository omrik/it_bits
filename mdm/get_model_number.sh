#!/bin/bash
# get_model_number.sh - MDM attribute: Apple order/model number, or the model identifier when there is none.
# Example output: MPHE3LL/A (Mac14,9)
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

hw=$(system_profiler SPHardwareDataType 2>/dev/null)
number=$(echo "$hw" | awk -F": " "/Model Number/ { print \$2; exit }")
ident=$(echo "$hw" | awk -F": " "/Model Identifier/ { print \$2; exit }")
if [ -n "$number" ]; then result "$number${ident:+ ($ident)}"
elif [ -n "$ident" ]; then result "$ident"
else result "unknown"; fi
