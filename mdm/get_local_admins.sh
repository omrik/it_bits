#!/bin/bash
# get_local_admins.sh - MDM attribute: local accounts in the admin group, comma-separated (root left out).
# Example output: omri, itadmin
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | sed "s/^GroupMembership: *//" | tr " " "\n" | grep -v -x -e root -e "" | paste -sd "," - | sed "s/,/, /g")
result "${admins:-none}"
