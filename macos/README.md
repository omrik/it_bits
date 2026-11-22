# macOS

## get_system_info.sh

A one-screen summary of a Mac: model, chip and cores, memory, serial, macOS version,
uptime, every mounted volume with free space, GPU, displays and battery health.
Handy for help-desk tickets, asset inventories, or checking a used Mac before you buy it.

### Requirements
None. It only uses tools built into macOS (`system_profiler`, `plutil`, `ioreg`) and runs
on Apple silicon and Intel Macs.

### Usage
```bash
get_system_info.sh [-p] [-a]
```

| Option | Meaning |
|---|---|
| `-p` | Private: leave out the serial number, e.g. when pasting into a ticket or chat |
| `-a` | All: after the summary, also print the full `system_profiler` reports it is built from (with `-p`, lines with serials and UUIDs are removed) |

### Example
```
$ ./get_system_info.sh -p
== Office-MacBook
Model        MacBook Pro (Mac14,9), MPHE3LL/A
Chip         Apple M2 Pro
Cores        10 cores (6 performance, 4 efficiency)
Memory       16 GB
macOS        macOS 15.1 (24B83)
Uptime       3d 4h 12m
Storage      Macintosh HD (/): 494 GB, 130 GB free - APPLE SSD AP0512Z (SSD)
GPU          Apple M2 Pro, 16 cores
Display      Color LCD: 1512 x 982 @ 120.00Hz
Battery      Good, 92% max capacity, 69 cycles
```

Lines are skipped when they don't apply, e.g. no `Battery` line on a desktop Mac.

## get_internet_accounts.sh

Lists the accounts set up in **System Settings → Internet Accounts** (iCloud, Google,
Microsoft Exchange, CalDAV, ...), with the account type, its name and the username.
Useful for offboarding checks ("is a personal iCloud or Google account still signed in on
this company Mac?") and for spotting accounts left behind by a previous user.

### Requirements
- **Full Disk Access** for whatever runs the script. The accounts database
  (`~/Library/Accounts/Accounts4.sqlite`) is protected by macOS privacy controls.
  - From Terminal: System Settings → Privacy & Security → Full Disk Access → add Terminal.
  - From an MDM: deploy a PPPC profile that grants Full Disk Access to the MDM agent
    (Jamf: `/usr/local/jamf/bin/jamf`; Intune: the Intune management agent).

  Without it the script prints `Cannot read ... give Full Disk Access ...` and exits with 2.
- Only tools built into macOS (`sqlite3`, `dscl`, `scutil`). The database is opened read-only.

### Usage
```bash
get_internet_accounts.sh [-a] [-p] [-t] [-j] [-u user]
```

| Option | Meaning |
|---|---|
| `-a` | All: also list inactive accounts and child accounts (e.g. the calendar under a Google account) |
| `-p` | Private: mask usernames, keeping the first letter and the domain (`j***@example.com`) |
| `-t` | Tab-separated output with a header row, for spreadsheets |
| `-j` | Wrap the output in `<result></result>` for a Jamf Pro extension attribute |
| `-u user` | Read this user's accounts. By default it reads your own, or the logged-in user's when run as root |

Exit codes: `0` ok, `1` bad option or no such user, `2` database missing or not readable.

### Example
```
$ ./get_internet_accounts.sh -p
Google | Work | j***@example.org
iCloud | iCloud | j***@example.com
```

### Using it from Jamf or Intune
Jamf extension attributes and Intune custom attributes can't take options, so set the
defaults at the top of the script instead, for example `JAMF=1` and `MASK=1`.
See the [mdm](../mdm/) folder for how to add a script to each. It runs as root and reads
the logged-in user's accounts; if nobody is logged in, the result is `No user logged in`.

Usernames are personal data. Check your privacy policy before collecting them across a
fleet, and consider `MASK=1`.
