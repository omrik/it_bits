#!/bin/bash
# get_ssd.sh - MDM attribute: name and size of the startup disk.
# Example output: APPLE SSD AP0512Z, 494 GB
# Upload to Jamf Pro (extension attribute) or Intune (macOS custom attribute); see README.md.
# By Omri Kedem. Cleaned up 2026.

FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
result() { if [ "$FORMAT" = jamf ]; then echo "<result>$1</result>"; else echo "$1"; fi; }

json=$(mktemp -t mdmssd) || exit 1
trap "rm -f \"\$json\"" EXIT
system_profiler -json -detailLevel mini SPStorageDataType > "$json" 2>/dev/null
n=$(plutil -extract SPStorageDataType raw -o - "$json" 2>/dev/null || echo 0)
for ((i = 0; i < n; i++)); do
  [ "$(plutil -extract SPStorageDataType.$i.mount_point raw -o - "$json" 2>/dev/null)" = "/" ] || continue
  name=$(plutil -extract SPStorageDataType.$i.physical_drive.device_name raw -o - "$json" 2>/dev/null)
  size=$(plutil -extract SPStorageDataType.$i.size_in_bytes raw -o - "$json" 2>/dev/null)
  result "${name:-unknown}${size:+, $((size / 1000000000)) GB}"
  exit 0
done
result "unknown"
