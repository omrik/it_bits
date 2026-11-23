# it_bits
IT scripts that are quick and useful - Just edit in vi

## Scripts
| Folder | Script | What it does |
|---|---|---|
| [speedtest](speedtest/) | `speedlog.sh` | Log Ookla speedtest results to a CSV |
| [dns](dns/) | `check_dns_list.sh` | Look up DNS records (MX, NS, TXT...) for a list of hosts |
| [dns](dns/) | `check_whois_list.sh` | Pull chosen whois fields (country, registrar, expiry...) for a list of IPs or domains |
| [macos](macos/) | `get_system_info.sh` | One-screen summary of a Mac: model, chip, memory, storage, GPU, displays, battery |
| [macos](macos/) | `get_internet_accounts.sh` | List the accounts in Internet Accounts (iCloud, Google, Exchange...) on a Mac |
| [ssl](ssl/) | `ssl_pfx_to_crt.sh` | Split a .pfx / .p12 into certificate, key, chain and fullchain PEM files |
| [mdm](mdm/) | `get_*.sh` (8 scripts) | One-value Mac attributes for Jamf Pro extension attributes and Intune custom attributes |

## More scripts
- [junos_it](https://github.com/omrik/junos_it): Juniper switch scripts (SNMP inventory, run commands on many switches, re-enable ports, roll out ssh keys)
