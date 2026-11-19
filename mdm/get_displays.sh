#!/bin/bash
# get_displays.sh - MDM attribute: connected displays with resolution, comma-separated (built-in screen included).
# Example output: Color LCD 1512 x 982, DELL U2723QE 3840 x 2160
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

# In system_profiler, each display is an indented "Name:" line followed by its details.
displays=$(system_profiler SPDisplaysDataType 2>/dev/null | awk "
  /^ {8}[^ ].*:\$/ { name = \$0; sub(/^ +/, \"\", name); sub(/:\$/, \"\", name) }
  /Resolution:/ && name != \"\" { res = \$0; sub(/.*Resolution: */, \"\", res); sub(/ *(Retina|\\(|@).*/, \"\", res)
                                   out = out (out ? \", \" : \"\") name \" \" res; name = \"\" }
  END { print out }")
result "${displays:-none}"
