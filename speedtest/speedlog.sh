#!/bin/bash

if [ $# -ne 1 ]; then
 echo "Usage: $0 <server_id> "
 speedtest -L
exit 1
fi

SERVER="$1"

speedtest -s "$SERVER" -f csv |
awk -v d="$(date '+%Y-%m-%d')" -v t="$(date '+%H:%M')" \
'{print d "," t "," $0}' >> speedlog.csv
