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
