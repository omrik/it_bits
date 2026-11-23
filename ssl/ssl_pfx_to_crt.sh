#!/bin/bash
#
# ssl_pfx_to_crt.sh - split a .pfx / .p12 file into PEM files for web servers
#
# For each input file NAME.pfx it writes:
#   NAME.crt            the certificate
#   NAME.key            the private key, unencrypted (mode 600)
#   NAME.chain.crt      the CA / intermediate certificates, if the file has any
#   NAME.fullchain.crt  certificate + chain, for nginx, HAProxy, ...
#
# Usage: ssl_pfx_to_crt.sh [-o dir] [-f] file.pfx [file2.p12 ...]
#   -o dir   write the files to dir (default: next to each input file)
#   -f       overwrite existing output files
#   -h       show this help
#
# The import password is asked once per file. To skip the prompt, put it in
# the PFX_PASSWORD environment variable (it is never passed on the command line).
#
# Exit codes: 0 ok, 1 bad usage, 2 a file failed (wrong password, not a pfx, ...)
#
# By Omri Kedem 07/2020, rewritten 2026

usage() { sed -n '3,21p' "$0" | sed 's/^# \{0,1\}//'; }

OUTDIR="" FORCE=0
while getopts ":o:fh" opt; do
  case $opt in
    o) OUTDIR=$OPTARG ;;
    f) FORCE=1 ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG needs a value" >&2; exit 1 ;;
    *) echo "Unknown option -$OPTARG" >&2; usage >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { usage >&2; exit 1; }
[ -z "$OUTDIR" ] || [ -d "$OUTDIR" ] || { echo "No such directory: $OUTDIR" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl not found" >&2; exit 1; }

# OpenSSL 3+ refuses old PFX files (RC2 / 3DES) unless -legacy is given.
LEGACY=""
openssl pkcs12 -help 2>&1 | grep -q -- '-legacy' && LEGACY="-legacy"

FAILED=0
for PFX in "$@"; do
  echo "== $PFX"
  if [ ! -r "$PFX" ]; then echo "   cannot read file" >&2; FAILED=1; continue; fi

  NAME=$(basename "$PFX"); NAME=${NAME%.*}
  DIR=${OUTDIR:-$(dirname "$PFX")}
  CRT="$DIR/$NAME.crt" KEY="$DIR/$NAME.key" CHAIN="$DIR/$NAME.chain.crt" FULL="$DIR/$NAME.fullchain.crt"

  if [ "$FORCE" = 0 ]; then
    for f in "$CRT" "$KEY" "$CHAIN" "$FULL"; do
      [ -e "$f" ] && { echo "   $f exists, use -f to overwrite" >&2; FAILED=1; continue 2; }
    done
  fi

  PW_SET=${PFX_PASSWORD+set}
  if [ -z "$PW_SET" ]; then
    read -r -s -p "   import password (empty for none): " PFX_PASSWORD < /dev/tty; echo
  fi
  export PFX_PASSWORD

  # Read the whole file once (with -legacy only if the normal read fails),
  # then pull the parts out of the PEM dump.
  PEM=$(openssl pkcs12 -in "$PFX" -nodes -passin env:PFX_PASSWORD 2>/dev/null) \
    || { [ -n "$LEGACY" ] && PEM=$(openssl pkcs12 $LEGACY -in "$PFX" -nodes -passin env:PFX_PASSWORD 2>/dev/null); } \
    || { echo "   cannot open: wrong password, or not a pfx/p12 file" >&2; FAILED=1; [ -z "$PW_SET" ] && unset PFX_PASSWORD; continue; }
  [ -z "$PW_SET" ] && unset PFX_PASSWORD

  # Private key (clean PEM, no "Bag Attributes" lines)
  KEYPEM=$(echo "$PEM" | awk '/-----BEGIN .*PRIVATE KEY-----/,/-----END .*PRIVATE KEY-----/')
  # All certificates, each one on its own
  CERTS=$(echo "$PEM" | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/')
  [ -n "$KEYPEM" ] || { echo "   no private key in this file" >&2; FAILED=1; continue; }
  [ -n "$CERTS" ]  || { echo "   no certificate in this file" >&2; FAILED=1; continue; }

  # The server certificate is the one whose public key matches the private key;
  # everything else is chain.
  KEYPUB=$(echo "$KEYPEM" | openssl pkey -pubout 2>/dev/null)
  LEAF="" REST=""
  while IFS= read -r -d '#' C; do
    [ -n "$C" ] || continue
    if [ -z "$LEAF" ] && [ "$(echo "$C" | openssl x509 -noout -pubkey 2>/dev/null)" = "$KEYPUB" ]; then
      LEAF=$C
    else
      REST="$REST$C"$'\n'
    fi
  done < <(echo "$CERTS" | awk '{print} /-----END CERTIFICATE-----/{print "#"}')
  [ -n "$LEAF" ] || { echo "   no certificate matches the private key" >&2; FAILED=1; continue; }
  LEAF=$(echo "$LEAF" | sed '/^$/d')
  REST=$(echo "$REST" | sed '/^$/d')

  (umask 077; echo "$KEYPEM" > "$KEY")
  echo "$LEAF" > "$CRT"
  if [ -n "$REST" ]; then
    echo "$REST" > "$CHAIN"
    printf '%s\n%s\n' "$LEAF" "$REST" > "$FULL"
  else
    rm -f "$CHAIN"
    echo "$LEAF" > "$FULL"
  fi

  SUBJ=$(openssl x509 -in "$CRT" -noout -subject 2>/dev/null | sed 's/^subject= *//')
  END=$(openssl x509 -in "$CRT" -noout -enddate 2>/dev/null | cut -d= -f2)
  NCHAIN=$(printf '%s' "$REST" | grep -c 'BEGIN CERTIFICATE')
  echo "   subject  $SUBJ"
  echo "   expires  $END"
  openssl x509 -in "$CRT" -noout -checkend 0 >/dev/null 2>&1 || echo "   WARNING: this certificate has expired"
  echo "   wrote    $CRT, $KEY, $FULL"
  [ "$NCHAIN" -gt 0 ] && echo "            $CHAIN ($NCHAIN CA certificate(s))"
done

exit $((FAILED * 2))
