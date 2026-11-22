#!/bin/bash
#
# get_internet_accounts.sh - list the accounts in System Settings -> Internet Accounts
#
# Reads the user's Accounts4.sqlite (read-only). Works when run as the user
# from Terminal, or as root from an MDM (then it reads the console user's
# database, or the user given with -u).
#
# Usage: get_internet_accounts.sh [-a] [-p] [-t] [-j] [-u user] [-h]
#   -a        all accounts: include inactive and child accounts (CalDAV, IMAP, ...)
#   -p        privacy: mask usernames (j***@example.com)
#   -t        tab-separated output, with a header row
#   -j        wrap the output in <result></result> for a Jamf extension attribute
#   -u user   read this user's accounts instead of the console user's
#   -h        show this help
#
# Exit codes: 0 ok, 1 bad option or no user, 2 database missing or not readable
#
# Needs Full Disk Access for whatever runs it (Terminal, or the MDM agent).

# Defaults. Jamf and Intune can't pass options to these scripts, so set them here.
ALL=0        # 1 = same as -a
MASK=0       # 1 = same as -p
TSV=0        # 1 = same as -t
JAMF=0       # 1 = same as -j (Jamf Pro extension attribute)
USER_NAME="" # same as -u

usage() { sed -n '3,19p' "$0" | sed 's/^# \{0,1\}//'; }

while getopts ":aptju:h" opt; do
  case $opt in
    a) ALL=1 ;;
    p) MASK=1 ;;
    t) TSV=1 ;;
    j) JAMF=1 ;;
    u) USER_NAME=$OPTARG ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG needs a value" >&2; exit 1 ;;
    *) echo "Unknown option -$OPTARG" >&2; usage >&2; exit 1 ;;
  esac
done

fail() {   # fail <exit code> <message>
  if [ "$JAMF" = 1 ]; then echo "<result>$2</result>"; else echo "$2" >&2; fi
  exit "$1"
}

# Whose accounts: -u, else the console user when running as root, else me.
if [ -z "$USER_NAME" ]; then
  if [ "$(id -u)" = 0 ]; then
    USER_NAME=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && !/loginwindow/ {print $3}')
  else
    USER_NAME=$(id -un)
  fi
fi
[ -n "$USER_NAME" ] || fail 1 "No user logged in"

HOME_DIR=$(/usr/bin/dscl . -read "/Users/$USER_NAME" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')
[ -n "$HOME_DIR" ] || fail 1 "Unknown user: $USER_NAME"

DB="${ACCOUNTS_DB:-$HOME_DIR/Library/Accounts/Accounts4.sqlite}"
[ -f "$DB" ] || fail 2 "No accounts database for $USER_NAME"

sql() { /usr/bin/sqlite3 -readonly -noheader -separator $'\t' "file:$DB?mode=ro" "$1" 2>/dev/null; }

# Schema check doubles as the permission check.
COLS=$(sql "SELECT name FROM pragma_table_info('ZACCOUNT');") \
  || fail 2 "Cannot read $DB - give Full Disk Access to whatever runs this script"
[ -n "$COLS" ] || fail 2 "Cannot read $DB - give Full Disk Access to whatever runs this script"
has() { echo "$COLS" | grep -qx "$1"; }

# Account type name ("Google", "iCloud", ...) when the type table is there.
if has ZACCOUNTTYPE && [ -n "$(sql "SELECT name FROM sqlite_master WHERE name='ZACCOUNTTYPE';")" ]; then
  TYPE="COALESCE(t.ZACCOUNTTYPEDESCRIPTION, '')"
  JOIN="LEFT JOIN ZACCOUNTTYPE t ON t.Z_PK = a.ZACCOUNTTYPE"
else
  TYPE="''" JOIN=""
fi

WHERE="1=1"
if [ "$ALL" = 0 ]; then
  WHERE="a.ZACTIVE = 1"
  has ZPARENTACCOUNT && WHERE="$WHERE AND a.ZPARENTACCOUNT IS NULL"
fi

ROWS=$(sql "SELECT $TYPE,
                   COALESCE(a.ZACCOUNTDESCRIPTION, ''),
                   COALESCE(a.ZUSERNAME, ''),
                   CASE a.ZACTIVE WHEN 1 THEN 'yes' ELSE 'no' END
            FROM ZACCOUNT a $JOIN
            WHERE $WHERE
            ORDER BY 1, 2;")

if [ "$MASK" = 1 ] && [ -n "$ROWS" ]; then
  # keep the first character and the domain of each username
  ROWS=$(echo "$ROWS" | /usr/bin/awk -F'\t' 'BEGIN{OFS="\t"} {
    u=$3
    if (u != "") { at=index(u,"@"); $3 = substr(u,1,1) "***" (at ? substr(u,at) : "") }
    print }')
fi

if [ "$TSV" = 1 ]; then
  OUT=$(printf 'type\tdescription\tusername\tactive\n'; [ -n "$ROWS" ] && echo "$ROWS")
elif [ -z "$ROWS" ]; then
  OUT="No accounts"
elif [ "$ALL" = 1 ]; then
  OUT=$(echo "$ROWS" | /usr/bin/awk -F'\t' '{printf "%s | %s | %s | active: %s\n", ($1==""?"-":$1), ($2==""?"-":$2), ($3==""?"-":$3), $4}')
else
  OUT=$(echo "$ROWS" | /usr/bin/awk -F'\t' '{printf "%s | %s | %s\n", ($1==""?"-":$1), ($2==""?"-":$2), ($3==""?"-":$3)}')
fi

if [ "$JAMF" = 1 ]; then echo "<result>$OUT</result>"; else echo "$OUT"; fi
