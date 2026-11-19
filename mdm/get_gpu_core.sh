#!/bin/bash
# get_gpu_core.sh - MDM attribute: number of GPU cores (Apple silicon; Intel and AMD GPUs do not report it).
# Example output: 16
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

cores=$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F": " "/Total Number of Cores/ { print \$2; exit }")
result "${cores:-n/a}"
