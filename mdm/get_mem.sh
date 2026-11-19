#!/bin/bash
# get_mem.sh - MDM attribute: installed memory (RAM).
# Example output: 16 GB
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

bytes=$(sysctl -n hw.memsize 2>/dev/null)
if [ -n "$bytes" ]; then result "$((bytes / 1073741824)) GB"; else result "unknown"; fi
