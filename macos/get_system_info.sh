#!/bin/bash
# get_system_info.sh - one-screen summary of a Mac: model, chip, memory, macOS, storage, GPU, displays, battery.
#
# Usage: get_system_info.sh [-p] [-a]
#   -p   private: leave out the serial number (for sharing in tickets or chats)
#   -a   all: also print the full system_profiler reports the summary is built from
#
# Works on Apple silicon and Intel Macs. Uses only built-in tools (system_profiler, plutil).
# By Omri Kedem, 01/2023. Cleaned up 2026.

set -uo pipefail

usage() { sed -n '4,6p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-2}"; }

private=0 all=0
while getopts ":pah" opt; do
  case $opt in
    p) private=1 ;;
    a) all=1 ;;
    h) usage 0 ;;
    *) echo "Unknown option -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 0 ] || usage
[ "$(uname -s)" = Darwin ] || { echo "This script only runs on macOS" >&2; exit 2; }

SECTIONS=(SPHardwareDataType SPSoftwareDataType SPStorageDataType SPDisplaysDataType SPPowerDataType)
json=$(mktemp -t sysinfo) || exit 1
trap 'rm -f "$json"' EXIT
system_profiler -json -detailLevel mini "${SECTIONS[@]}" > "$json" 2>/dev/null \
  || { echo "system_profiler failed" >&2; exit 1; }

# get <key.path>: one value from the report, empty if missing.
get() { plutil -extract "$1" raw -o - "$json" 2>/dev/null; }
# count <key.path>: number of items in an array, 0 if missing.
count() { local n; n=$(get "$1"); [[ "$n" =~ ^[0-9]+$ ]] && echo "$n" || echo 0; }
gb() { awk -v b="$1" 'BEGIN { printf "%.0f GB", b / 1e9 }'; }
row() { [ -n "$2" ] && printf '%-12s %s\n' "$1" "$2"; return 0; }

H=SPHardwareDataType.0
model="$(get $H.machine_name) ($(get $H.machine_model))"
modelnum=$(get $H.model_number)
chip=$(get $H.chip_type)
if [ -n "$chip" ]; then
  # Apple silicon: "proc 10:0:6:4" = total:?:performance:efficiency
  IFS=: read -r total _ perf eff <<< "$(get $H.number_processors | sed 's/^proc //')"
  cores="$total cores ($perf performance, $eff efficiency)"
else
  chip="$(get $H.cpu_type) $(get $H.current_processor_speed)"
  cores="$(get $H.number_processors) cores"
fi

echo "== $(scutil --get ComputerName 2>/dev/null || hostname)"
row "Model"   "$model${modelnum:+, $modelnum}"
row "Chip"    "$chip"
row "Cores"   "$cores"
row "Memory"  "$(get $H.physical_memory)"
# -detailLevel mini omits the serial, so read it from the I/O registry.
[ "$private" -eq 1 ] || row "Serial" "$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F'"' '/IOPlatformSerialNumber/ { print $(NF-1) }')"
row "macOS"   "$(get SPSoftwareDataType.0.os_version)"
# uptime comes as "up D:H:M:S"
row "Uptime"  "$(get SPSoftwareDataType.0.uptime | awk -F: '{ sub(/^up /, ""); if (NF == 4) printf "%dd %dh %dm", $1, $2, $3; else print }')"

# Storage: every mounted volume except the APFS system/data duplicates.
n=$(count SPStorageDataType)
for ((i = 0; i < n; i++)); do
  S=SPStorageDataType.$i
  mount=$(get $S.mount_point)
  case $mount in /System/Volumes/*|"") continue ;; esac
  size=$(get $S.size_in_bytes) free=$(get $S.free_space_in_bytes)
  drive=$(get $S.physical_drive.device_name) medium=$(get $S.physical_drive.medium_type | tr '[:lower:]' '[:upper:]')
  row "Storage" "$(get $S._name) ($mount): $(gb "$size"), $(gb "$free") free${drive:+ - $drive}${medium:+ ($medium)}"
done

n=$(count SPDisplaysDataType)
for ((i = 0; i < n; i++)); do
  D=SPDisplaysDataType.$i
  gcores=$(get $D.sppci_cores)
  row "GPU" "$(get $D.sppci_model)${gcores:+, $gcores cores}"
  m=$(count $D.spdisplays_ndrvs)
  for ((j = 0; j < m; j++)); do
    row "Display" "$(get $D.spdisplays_ndrvs.$j._name): $(get $D.spdisplays_ndrvs.$j._spdisplays_resolution)"
  done
done

B=SPPowerDataType.0.sppower_battery_health_info
cycles=$(get $B.sppower_battery_cycle_count)
[ -n "$cycles" ] && row "Battery" "$(get $B.sppower_battery_health), $(get $B.sppower_battery_health_maximum_capacity) max capacity, $cycles cycles"

if [ "$all" -eq 1 ]; then
  echo; echo "== Full reports"
  if [ "$private" -eq 1 ]; then
    system_profiler "${SECTIONS[@]}" 2>/dev/null | grep -v -i -E 'serial|uuid|udid'
  else
    system_profiler "${SECTIONS[@]}" 2>/dev/null
  fi
fi
exit 0
