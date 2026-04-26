# pfBlockerNG Manager Roadmap

PowerShell WPF GUI for managing pfBlockerNG on pfSense via SSH + PHP API. Roadmap deepens visibility (dashboards, analytics, historic trends) and adds multi-host plus non-pfSense DNSBL support.

## Planned Features

### Monitoring
- Historic DNS block trend (daily / weekly rollups, CSV + chart)
- Top-N dashboard: blocked domains, clients, categories, countries (24h/7d/30d)
- Per-client drill-down view with timeline + top queries
- Feed effectiveness score — hits per feed so dead feeds get flagged
- Alert rules with desktop toast + optional Slack/Discord webhook

### List Management
- Bulk paste / file import for whitelist and blocklist
- Domain category tagger (shopping, tracking, NSFW) with bulk actions
- Regex / wildcard preview tester before commit
- Scheduled whitelist (e.g. temp allow for 1h, auto-revert)
- Diff view between local JSON backup and live pfSense config

### Multi-host
- Manage multiple pfSense boxes from one window (tabs or tree)
- Config sync — push whitelist/blocklist from golden host to the rest
- Federated stats view (aggregate across all connected firewalls)
- SSH key auth (beyond password)

### pfSense-adjacent Backends
- Adapter layer for AdGuard Home REST API
- Adapter layer for Pi-hole v6 API
- Adapter layer for Unbound-only deployments (no pfBlocker)
- Common list-editor UI across all backends

### Quality
- Full keyboard nav + accessibility pass on all tabs
- Export full session (logs + stats) as HTML report
- Settings profile import/export signed and versioned
- Portable mode (config in same folder, USB-run friendly)

## Competitive Research
- **Pi-hole dashboard** — gold standard for DNS block visibility. Lesson: steal the query-log UX and per-client drill-down shape.
- **AdGuard Home web UI** — filter rules + custom DNS + DHCP. Lesson: show rule hit counts inline so users can prune dead lists.
- **NextDNS / ControlD dashboards** — cloud DNS with profile tagging. Lesson: add tags to domains and report by tag, not just feed.
- **pfSense native UI** — baseline; missing real-time monitor and good list editor. Lesson: this tool's unique value is in real-time streaming plus bulk list edits.

## Nice-to-Haves
- Mobile companion (Flutter / Kivy) for on-the-go whitelist
- REST proxy mode — expose a tiny local API so other tools can query stats
- MaxMind GeoIP enrichment for IP block tab
- Scheduled report email (PS `Send-MailMessage` or Graph)
- DoT / DoH enforcement auditor (warn on clients bypassing Unbound)
- Light theme that actually matches pfSense branding

## Open-Source Research (Round 2)

### Related OSS Projects
- https://github.com/ahuacate/pfsense-pfblockerng — Canonical pfBlockerNG configuration guide, community-maintained.
- https://github.com/christopherbradski/pfsense-addons — dns_based_ip_whitelister; automated alias/rule updates via pfSense-API.
- https://github.com/ChiefGyk3D/pfsense-siem-stack — Interactive console + OpenSearch dashboards for pfBlockerNG stats.
- https://github.com/pfsense/pfsense-packages — Upstream pfBlockerNG source under `config/pfblockerng/`.
- https://github.com/jaredhendrickson13/pfsense-api — Third-party REST API covering most pfSense surfaces (deprecated but widely used).
- https://github.com/mikael-andre/pfSense — HOWTO wiki with pfBlockerNG recipes.
- https://github.com/pavanagowda05/Network-Traffic-Filtering-with-pfSense — DNS-based URL blocking recipes.
- https://github.com/netgate/pfsense-restapi — Netgate's official REST API (pfSense Plus / 2.8+).

### Features to Borrow
- pfSense-API-driven alias automation pattern — same-credential webConfigurator auth (christopherbradski).
- DNS-lookup-driven whitelist expansion — resolve `*.docker.io` then update IP alias (christopherbradski). Great sidekick to the existing whitelist button.
- OpenSearch/InfluxDB dashboard JSON bundled in-repo for `pfsense_pfblockerng_system` + Suricata (ChiefGyk3D).
- Interactive console "wizard" for first-run bootstrap (ChiefGyk3D).
- Per-rule hit-count UI with bar sparkline (pfBlockerNG internal PHP API).
- Scheduled feed-refresh + cron status panel (upstream pfBlockerNG).
- DNSBL suppression list round-trip editor with bulk import (upstream).
- GeoIP country-pack visual map tied to feed toggles.

### Patterns & Architectures Worth Studying
- **Shared-credential pattern** — reuse webConfigurator creds so no secondary secret storage is needed (christopherbradski).
- **Netgate REST API-first** design — move all pfBlockerNG manipulation off SSH/PHP exec and onto REST; cleaner permissions and versioning.
- **Event-stream pattern** — tail `/var/log/pfblockerng/*.log` over SSH via async PowerShell runspace and fan out to WPF Live tab.
- **JSON schema for exported configs** — validates before import, prevents half-written pfBlockerNG state.
- **Dashboard-as-artifact** — ship Grafana + OpenSearch dashboard JSON alongside the GUI so ops teams can wire pfBNG into existing SIEM stacks.
