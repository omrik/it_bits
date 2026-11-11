# DNS

## check_dns_list.sh

Look up DNS records for a whole list of hosts in one go, e.g. to check MX or NS
records after a migration, or to audit TXT/SPF records across all your domains.

### Requirements
`dig`, which is built into macOS. On Linux, install `dnsutils` (Debian/Ubuntu) or `bind-utils` (RHEL/Fedora).

### Usage
```bash
check_dns_list.sh [-s server] [-t] <host_list_file|-> <type> [type...]
```

| Argument | Meaning |
|---|---|
| `host_list_file` | One host per line. Blank lines and `#` comments are ignored. Use `-` to read from stdin. |
| `type` | One or more record types: `a`, `aaaa`, `mx`, `ns`, `txt`, `soa`, `cname`, `caa`... |
| `-s server` | Query this resolver instead of the system default, e.g. `1.1.1.1` |
| `-t` | Tab-separated output (`host`, `type`, `value`), one line per record, ready for a spreadsheet |

### Examples
```bash
# MX and NS for every domain in the list
./check_dns_list.sh domains.txt mx ns

# Ask Google's resolver instead of your own
./check_dns_list.sh -s 8.8.8.8 domains.txt soa

# One host from stdin, TSV out
echo example.com | ./check_dns_list.sh -t - txt > txt-records.tsv
```

Example `domains.txt`:
```
# production
example.com
example.org   # legacy
```

Output:
```
example.com
  MX    0 .
  NS    hera.ns.cloudflare.com.
  NS    elliott.ns.cloudflare.com.
no-such-domain.invalid
  MX    (no MX record)
```

### Exit codes
| Code | Meaning |
|---|---|
| 0 | Every host returned a record for every type |
| 1 | At least one host had no record or the lookup failed (useful in cron/CI checks) |
| 2 | Usage error: bad arguments, unreadable file, or `dig` missing |
