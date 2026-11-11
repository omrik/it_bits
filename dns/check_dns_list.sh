#!/bin/bash
# check_dns_list.sh - look up one or more DNS record types for every host in a list.
#
# Usage: check_dns_list.sh [-s server] [-t] <host_list_file|-> <type> [type...]
#   host_list_file  one host per line; blank lines and # comments are ignored; "-" reads stdin
#   type            DNS record type: a, aaaa, mx, ns, txt, soa, cname, caa ... (any type dig knows)
#   -s server       ask this resolver instead of the system default (e.g. 1.1.1.1)
#   -t              tab-separated output: host<TAB>type<TAB>value (one line per record)
#
# Examples:
#   check_dns_list.sh domains.txt mx
#   check_dns_list.sh -s 8.8.8.8 domains.txt ns soa
#   echo example.com | check_dns_list.sh -t - txt > txt-records.tsv
#
# Exit codes: 0 every lookup answered, 1 at least one host had no record or failed, 2 usage error.
# By Omri Kedem, 04/2008. Cleaned up 2026.

set -uo pipefail

usage() { sed -n '4,8p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-2}"; }

server="" tsv=0
while getopts ":s:th" opt; do
  case $opt in
    s) server="@$OPTARG" ;;
    t) tsv=1 ;;
    h) usage 0 ;;
    :) echo "Option -$OPTARG needs a value" >&2; usage ;;
    *) echo "Unknown option -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -ge 2 ] || usage

command -v dig >/dev/null || { echo "dig not found (macOS has it; on Linux install dnsutils / bind-utils)" >&2; exit 2; }

list="$1"; shift
types=("$@")
src="$list"; [ "$list" = "-" ] && src=/dev/stdin
[ "$src" = /dev/stdin ] || [ -r "$src" ] || { echo "Cannot read host list: $list" >&2; exit 2; }

# Strip comments and whitespace, skip blank lines.
hosts=$(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$src")
[ -n "$hosts" ] || { echo "No hosts in $list" >&2; exit 2; }

status=0
while IFS= read -r host; do
  [ "$tsv" -eq 1 ] || echo "$host"
  for type in "${types[@]}"; do
    TYPE=$(printf '%s' "$type" | tr '[:lower:]' '[:upper:]')
    # shellcheck disable=SC2086  # $server is empty or a single @resolver word
    if ! answer=$(dig +short +time=3 +tries=2 $server "$host" "$TYPE" 2>&1); then
      answer=""; err="lookup failed"
    else
      err="no $TYPE record"
    fi
    # dig +short prints ";; ..." lines on timeouts
    answer=$(printf '%s\n' "$answer" | grep -v '^;;' || true)
    if [ -z "$answer" ]; then
      status=1
      if [ "$tsv" -eq 1 ]; then printf '%s\t%s\t%s\n' "$host" "$TYPE" "($err)"
      else printf '  %-5s (%s)\n' "$TYPE" "$err"; fi
      continue
    fi
    while IFS= read -r value; do
      if [ "$tsv" -eq 1 ]; then printf '%s\t%s\t%s\n' "$host" "$TYPE" "$value"
      else printf '  %-5s %s\n' "$TYPE" "$value"; fi
    done <<< "$answer"
  done
done <<< "$hosts"

exit $status
