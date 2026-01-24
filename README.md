# pfBlockerNG Manager v3.5

Comprehensive PowerShell GUI for managing pfBlockerNG on pfSense firewalls.

## What's New in v3.5

### Fixed Whitelist/Blocklist
- Now properly integrates with pfBlockerNG's configuration system
- Uses pfBlockerNG's PHP API for reliable list management
- Instant effect via Unbound + persistent config.xml storage
- Properly adds to DNSBL suppression list (whitelist) and custom blocklist

### Live Monitor Tab (Now First/Default)
- Added whitelist/blocklist buttons for quick actions
- Added VirusTotal lookup button
- Added Copy Domain/IP buttons
- Shows DNS blocked, DNS allowed, AND IP blocks in real-time

### New IP Blocking Tab
- View pfBlockerNG IP block logs
- Statistics: total blocks, inbound, outbound, active tables
- Export IP logs to CSV
- AbuseIPDB lookup integration

### Settings Panel
- Click "Settings" button in header
- Show/hide individual tabs
- Toggle auto-refresh on tab change
- Configure Live Monitor max entries
- Theme selection (Dark/Light)

### Auto-Refresh on Tab Change
- Data automatically refreshes when switching tabs
- Can be disabled in Settings

## Tab Overview

| Tab | Description |
|-----|-------------|
| **Live Monitor** | Real-time streaming of DNS and IP events |
| **DNS Logs** | View/filter blocked and allowed DNS queries |
| **IP Blocking** | View IP block events and statistics |
| **List Editor** | Edit whitelist and blocklist |
| **Statistics** | Per-client stats, top domains |
| **DNS Lookup** | Test if domain would be blocked |
| **Alerts** | Create domain alert rules |
| **Feeds** | View DNSBL feed status |
| **System** | Firewall management, backup/restore |

## Whitelist/Blocklist - How It Works Now

The whitelist and blocklist functions now properly integrate with pfBlockerNG:

**Whitelist (DNSBL Suppression):**
- Domains added to pfBlockerNG's suppression list in config.xml
- Immediately removed from Unbound DNSBL
- Persists through DNSBL reloads
- Format: `.example.com` for wildcard, `example.com` for exact

**Blocklist (Custom Block):**
- Domains added to pfBlockerNG's custom blocklist
- Immediately added to Unbound as `always_nxdomain`
- Persists through DNSBL reloads

## Requirements

### Windows
- Windows 10/11
- PowerShell 5.1+
- Posh-SSH module (auto-installs)

### pfSense
1. SSH enabled (System > Advanced > Admin Access)
2. pfBlockerNG-devel installed
3. DNSBL enabled with Unbound mode
4. DNS Reply Logging enabled (for allowed queries)

## Installation

1. Download `pfBlockerNG-Manager.ps1` and `Launch-Manager.bat`
2. Double-click `Launch-Manager.bat`
3. If prompted, allow Posh-SSH installation

## Quick Start

1. Enter pfSense IP, port (22), username, password
2. Check "Save" to remember credentials
3. Click **Connect**
4. Live Monitor starts as default tab
5. Click "Start Streaming" to watch real-time events

## Settings

Click the **Settings** button to customize:

- **Theme**: Dark or Light
- **Visible Tabs**: Show/hide any tab
- **Auto-refresh on tab change**: Enable/disable
- **Live Monitor max entries**: Default 500

## Keyboard Shortcuts (in Live Monitor)

- Select an entry, then click:
  - `+ Whitelist` - Add domain to whitelist
  - `+ Blocklist` - Add domain to blocklist
  - `VirusTotal` - Open VirusTotal lookup
  - `Copy Domain` - Copy domain to clipboard
  - `Copy IP` - Copy IP to clipboard

## File Locations

**Windows:**
```
%APPDATA%\pfBlockerNG-Manager\
  config.json    - Saved credentials (encrypted)
  settings.json  - App settings
  alerts.json    - Alert rules
```

**pfSense:**
```
/var/log/pfblockerng/dnsbl.log      - DNS blocked queries
/var/log/pfblockerng/dns_reply.log  - DNS allowed queries
/var/log/pfblockerng/ip_block.log   - IP block events
```

## Troubleshooting

### Whitelist/Blocklist Not Working
1. Ensure pfBlockerNG-devel is installed (not the regular version)
2. Ensure DNSBL is enabled and in Unbound mode
3. After adding entries, click "Reload DNSBL" in System tab
4. Check that domains appear in List Editor tab after refresh

### No DNS Reply Logs
1. In pfSense: Firewall > pfBlockerNG > DNSBL
2. Enable "DNS Reply Logging"
3. Set DNSBL Mode to "Unbound python mode"
4. Save and reload DNSBL

### IP Block Tab Empty
1. Ensure pfBlockerNG IP blocking is enabled
2. Check that IP feeds are configured and active
3. IP blocks may be less frequent than DNS blocks

## License

MIT License - Free to use and modify.
