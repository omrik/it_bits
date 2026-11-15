#!/bin/bash
# check_whois_list.sh - pull chosen whois fields for every IP or domain in a list.
#
# Usage: check_whois_list.sh [-t] [-d seconds] <host_list_file|-> <field> [field...]
#   host_list_file  one IP or domain per line; blank lines and # comments are ignored; "-" reads stdin
#   field           whois field name, case-insensitive (country, netname, registrar); end with * to match a prefix (registrar*)
#   -t              tab-separated output: host<TAB>field<TAB>value (one line per match)
#   -d seconds      pause between lookups so whois servers don't rate-limit you (default 1)
#
# Examples:
#   check_whois_list.sh ips.txt country netname descr
#   check_whois_list.sh domains.txt registrar "registry expiry date" "name server"
#   echo 1.1.1.1 | check_whois_list.sh -t - country orgname > whois.tsv
#
# Exit codes: 0 every host matched every field, 1 at least one field or lookup came back empty, 2 usage error.
# By Omri Kedem, 04/2008. Cleaned up 2026.

set -uo pipefail

usage() { sed -n '4,8p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-2}"; }

tsv=0 delay=1
while getopts ":td:h" opt; do
  case $opt in
    t) tsv=1 ;;
    d) delay="$OPTARG" ;;
    h) usage 0 ;;
    :) echo "Option -$OPTARG needs a value" >&2; usage ;;
    *) echo "Unknown option -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -ge 2 ] || usage
[[ "$delay" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "-d needs a number of seconds" >&2; exit 2; }

command -v whois >/dev/null || { echo "whois not found (macOS has it; on Linux install the whois package)" >&2; exit 2; }

list="$1"; shift
fields=("$@")
src="$list"; [ "$list" = "-" ] && src=/dev/stdin
[ "$src" = /dev/stdin ] || [ -r "$src" ] || { echo "Cannot read host list: $list" >&2; exit 2; }

# Strip comments and whitespace, skip blank lines.
hosts=$(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$src")
[ -n "$hosts" ] || { echo "No hosts in $list" >&2; exit 2; }

status=0 first=1
while IFS= read -r host; do
  [ "$first" -eq 1 ] || sleep "$delay"; first=0
  [ "$tsv" -eq 1 ] || echo "$host"
  # Drop comment/legal lines (%, #, >>>) and Windows line endings.
  if ! record=$(whois "$host" 2>/dev/null | tr -d '\r' | grep -v -E '^[[:space:]]*(%|#|>>>)'); then record=""; fi
  if [ -z "$record" ]; then
    status=1
    if [ "$tsv" -eq 1 ]; then printf '%s\t%s\t%s\n' "$host" "-" "(whois lookup failed)"
    else echo "  (whois lookup failed)"; fi
    continue
  fi
  for field in "${fields[@]}"; do
    # Match "field:" exactly (or as a prefix when it ends in *), case-insensitive; keep each distinct value once.
    values=$(printf '%s\n' "$record" | awk -v f="$field" '
      BEGIN { f = tolower(f); pre = (substr(f, length(f)) == "*"); if (pre) f = substr(f, 1, length(f) - 1) }
      { line = $0; sub(/^[[:space:]]+/, "", line)
        i = index(line, ":"); if (i == 0) next
        key = tolower(substr(line, 1, i - 1))
        sub(/[[:space:]]+$/, "", key)
        if (pre ? index(key, f) != 1 : key != f) next
        val = substr(line, i + 1); sub(/^[[:space:]]+/, "", val); sub(/[[:space:]]+$/, "", val)
        if (val != "" && !seen[key SUBSEP tolower(val)]++) print substr(line, 1, i - 1) "\t" val }')
    if [ -z "$values" ]; then
      status=1
      if [ "$tsv" -eq 1 ]; then printf '%s\t%s\t%s\n' "$host" "$field" "(not found)"
      else printf '  %-22s (not found)\n' "$field"; fi
      continue
    fi
    while IFS=$'\t' read -r key val; do
      if [ "$tsv" -eq 1 ]; then printf '%s\t%s\t%s\n' "$host" "$key" "$val"
      else printf '  %-22s %s\n' "$key" "$val"; fi
    done <<< "$values"
  done
done <<< "$hosts"

exit $status
