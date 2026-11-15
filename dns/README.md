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

## check_whois_list.sh

Pull just the whois fields you care about for a list of IPs or domains, e.g. which
country and network a batch of IPs from a log belongs to, or the registrar and expiry
date of every domain you own.

### Requirements
`whois`, which is built into macOS. On Linux, install the `whois` package.

### Usage
```bash
check_whois_list.sh [-t] [-d seconds] <host_list_file|-> <field> [field...]
```

| Argument | Meaning |
|---|---|
| `host_list_file` | One IP or domain per line. Blank lines and `#` comments are ignored. Use `-` to read from stdin. |
| `field` | Whois field name, case-insensitive: `country`, `netname`, `orgname`, `registrar`... End it with `*` to match every field that starts with it (`'registrar*'`). |
| `-t` | Tab-separated output (`host`, `field`, `value`), one line per value |
| `-d seconds` | Pause between lookups (default `1`) so whois servers don't rate-limit you |

Field names differ between registries. Run `whois <host>` once to see the names a
registry uses. Some common ones:

| Looking up | Useful fields |
|---|---|
| IPs (ARIN) | `netname`, `orgname`, `country`, `cidr` |
| IPs (RIPE, APNIC) | `netname`, `descr`, `country`, `inetnum` |
| .com / .net / .org | `registrar`, `"registry expiry date"`, `"name server"` |
| .il | `"registrar name"`, `nserver`, `validity` |

### Examples
```bash
# Who owns these IPs?
./check_whois_list.sh ips.txt country netname orgname

# Registrar and expiry for all your domains, as a spreadsheet
./check_whois_list.sh -t domains.txt registrar "registry expiry date" > domains.tsv

# Every registrar-abuse field for one domain
echo github.com | ./check_whois_list.sh - 'registrar abuse*'
```

Output:
```
github.com
  Registrar              MarkMonitor Inc.
  Registry Expiry Date   2028-10-09T18:20:50Z
1.1.1.1
  registrar              (not found)
  country                AU
```

### Exit codes
| Code | Meaning |
|---|---|
| 0 | Every host returned every field |
| 1 | At least one field was not found or a lookup failed |
| 2 | Usage error: bad arguments, unreadable file, or `whois` missing |
