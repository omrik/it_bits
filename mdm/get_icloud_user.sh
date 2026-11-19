#!/bin/bash
# get_icloud_user.sh - MDM attribute: Apple Account (iCloud) signed in by the user at the console.
# Example output: user@icloud.com
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

# MDM scripts run as root, so look up whoever is logged in at the screen.
user=$(echo "show State:/Users/ConsoleUser" | scutil | awk "/Name :/ && ! /loginwindow/ { print \$3 }")
plist="/Users/$user/Library/Preferences/MobileMeAccounts.plist"
if [ -z "$user" ]; then result "no user logged in"; exit 0; fi
# Check first: PlistBuddy prints a "Will Create" notice (not an error) for a missing file.
[ -f "$plist" ] || { result "none"; exit 0; }
account=$(/usr/libexec/PlistBuddy -c "Print :Accounts:0:AccountID" "$plist" 2>/dev/null)
result "${account:-none}"
