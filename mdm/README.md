# MDM attributes

Tiny scripts that each report **one value** about a Mac, such as RAM, GPU or local admins,
so your MDM can collect it from every computer and show it in the device inventory.
Use them as **extension attributes** in Jamf Pro or **custom attributes** in Microsoft Intune.
You can then search, filter, report on, or build smart groups from the values.

| Script | Reports | Example |
|---|---|---|
| `get_mem.sh` | Installed memory | `16 GB` |
| `get_model_number.sh` | Apple model number (model identifier) | `MPHE3LL/A (Mac14,9)` |
| `get_chipset.sh` | Graphics chip(s) | `Apple M2 Pro` |
| `get_gpu_core.sh` | GPU core count (Apple silicon only, otherwise `n/a`) | `16` |
| `get_displays.sh` | Connected displays and resolution | `Color LCD 3024 x 1964, DELL U2723QE 3840 x 2160` |
| `get_ssd.sh` | Startup disk name and size | `APPLE SSD AP0512Z, 494 GB` |
| `get_local_admins.sh` | Accounts in the local admin group (not `root`) | `jane, itadmin` |
| `get_icloud_user.sh` | Apple Account signed in by the logged-in user | `jane@icloud.com` or `none` |

Each script is self-contained, so you can upload it on its own, and uses only tools built into macOS.
The MDM runs them as root.

## Output format: set `FORMAT` first
Jamf and Intune expect slightly different output, so every script has this line near the top:

```bash
FORMAT="plain"   # plain = Intune custom attribute or Terminal; jamf = Jamf Pro extension attribute
```

| `FORMAT` | Output | Use for |
|---|---|---|
| `plain` (default) | `16 GB` | Intune, or running it yourself |
| `jamf` | `<result>16 GB</result>` | Jamf Pro: it only stores what is inside `<result>` tags |

## Jamf Pro: extension attribute
1. In Jamf Pro, go to **Settings → Computer management → Extension attributes → New**.
2. Enter a **Display name** (for example "Installed memory"), set **Data type** to *String*
   and **Input type** to *Script*.
3. Paste in the script, with `FORMAT="jamf"`, and save.
4. Values arrive with each computer's next inventory update. To update one Mac now, run `sudo jamf recon` on it.
5. The values show up in each computer's inventory record (Extension Attributes) and can be
   used as criteria in **Smart computer groups** and **Advanced searches**.

## Microsoft Intune: macOS custom attribute
1. In the Intune admin center, go to **Devices → macOS → Custom attributes → Add**.
2. Name it, set **Data type of attribute** to *String*, and upload the script, leaving `FORMAT="plain"`.
3. Assign it to a group of devices or users.
4. The Intune management agent runs it on each Mac and reports the output, roughly every 8 hours.
   See the results under the custom attribute's **Device status**.

The Mac must have the Intune management agent, which installs with the first shell script or
custom attribute you assign.

## Test locally first
```bash
./get_mem.sh                  # plain output
sudo ./get_local_admins.sh    # run as root, the way the MDM will
```

## Notes
- `get_icloud_user.sh` looks up whoever is logged in at the screen. It reports `no user logged in`
  at the login window and `none` if the user isn't signed in to iCloud.
- The account values (`get_local_admins.sh`, `get_icloud_user.sh`) are personal data. Collect
  them only where your policies allow it.
