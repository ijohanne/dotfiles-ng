# Movistar IPTV (Imagenio) Setup

Documents how the Movistar STB (HUMAX PTT1000) works on goose and what's needed.

## Network Path

```
Movistar ONT/Router (192.168.1.1)
    │
    └── VLAN 253 (wan) ──┐
                          ├── br-wan bridge on goose
    └── VLAN 252 (stb) ──┘
                          │
                     goose (192.168.1.2 on br-wan)
                          │
                     PPPoE (ppp0) → public internet
                          │
                     VLAN 101 (wired) ← STB (10.255.101.201)
```

The STB is on VLAN 101 (wired). Movistar IPTV traffic from the ISP arrives on VLAN 253 (wan) via the Movistar router at 192.168.1.1. VLANs 252 (stb) and 253 (wan) are bridged together as `br-wan` for debugging — devices placed on VLAN 252 get direct L2 access to the Movistar router, allowing traffic capture on goose.

## STB Boot Sequence

1. DHCP Discover with vendor class `[IAL]` and client-id type 72 (`HUMAX_PTT1000_ES_...`)
2. Kea responds with IP, DNS (172.26.23.3), and DHCP option 240 (multicast config)
3. STB joins multicast group 239.0.2.30 (service discovery)
4. DNS lookup `main.acs.telefonica.net` → 80.58.63.218 (ACS/TR-069 server)
5. STB attempts TLS to ACS on port 7016 — **blocked by firewall** (see below)
6. STB falls back to internal services:
   - DNS `www-60.svc.imagenio.telefonica.net` via 172.26.23.3 → 172.23.103.134
   - Connects to 172.23.103.134:2001 for provisioning data
   - Connects to 172.26.83.77:80 for EPG/content metadata
   - Sends telemetry to 172.23.101.96:9154 (`POST /events/monitoring`)
7. Joins multicast groups for live TV channels

## ACS Block (80.58.63.218)

The Movistar ACS server presents a TLS certificate (issued by PKI SubCA TI TELEFONICA ESP) that the STB firmware rejects with a fatal `bad_certificate` alert (42). This causes the STB to abort boot entirely.

When ACS is **unreachable** (ICMP reject), the STB gracefully skips it and proceeds to boot via Movistar's internal 172.x services. The firewall blocks the STB from reaching ACS to trigger this fallback:

```nix
ip saddr ${network.hosts.livingroom-movistar-stb.ip} ip daddr 80.58.63.218 reject
```

## Required Static Routes

Traffic to Movistar internal networks must go via the Movistar router (192.168.1.1) on br-wan, not via ppp0:

| Destination | Purpose |
|---|---|
| 172.26.0.0/17 | IPTV services, DNS (172.26.23.3), EPG, CDN |
| 172.23.0.0/17 | IPTV provisioning, STB services |
| 10.31.255.128/27 | Movistar infrastructure |
| 10.93.18.0/24 | Telefonica PKI servers |

These are set by `movistar-routes.service` at boot and restored by the PPP `ip-up.d/10-post-up.sh` script after PPPoE reconnects (ppp0's `replacedefaultroute` wipes them).

## DHCP Configuration (kea.nix)

The `MovistarTV` client class matches `[IAL]` vendor class and provides:
- **Option 6** (DNS): 172.26.23.3 (Movistar internal DNS)
- **Option 240**: `:::::239.0.2.10:22222:v6.0:239.0.2.30:22222` (multicast discovery config)

The STB also requests options 125, 170, 241, 242, 243 — these are not currently served.

## Multicast / Live TV

- `igmpproxy` runs with br-wan as upstream, wired/wifi as downstream
- NAT prerouting DNAT rules for 172.26.0.0/16 and 172.23.0.0/16 exclude multicast (`ip daddr != 224.0.0.0/4`) to avoid rewriting multicast destinations
- Multicast groups used: 239.0.2.x (service discovery, channels), 239.0.5.x (additional channels)

## VOD (Video on Demand)

VOD uses DASH streaming. The flow:

1. STB requests manifest from CDN (172.26.82.15:80)
2. CDN returns **HTTP 302 redirect** to a per-session hostname like `b42190-p1050-h17-v0-*.1.cdn.telefonica.com`
3. STB resolves this hostname — it points to 172.26.82.x (Movistar internal CDN)
4. STB streams DASH segments from the CDN

VOD requires DNS resolution of `cdn.telefonica.com` subdomains. The STB tries both Movistar internal DNS (172.26.23.3) and public Movistar DNS (80.58.61.250/254). When on wired VLAN, public DNS goes via ppp0 — this works. When bridged on VLAN 252, public DNS is unreachable since the Movistar router can't route to public IPs from its LAN side.

## VLAN 252 Debug Bridge

VLANs 252 (stb) and 253 (wan) are bridged as `br-wan`. To capture STB traffic at L2:

1. Move the STB's switch port to VLAN 252
2. `tcpdump -i br-wan ether host e8:b2:fe:06:a1:28`
3. All traffic between STB and Movistar router flows through goose

PPPoE and the 192.168.1.2 IP are on the bridge interface. This setup is transparent — the STB gets DHCP from the Movistar router (192.168.1.200) and communicates directly at L2.

## Key Movistar IPs

| IP | Role |
|---|---|
| 192.168.1.1 | Movistar ONT/Router (gateway for IPTV networks) |
| 172.26.23.3 | Movistar internal DNS |
| 80.58.63.218 | ACS/TR-069 management server (port 7016/7018) |
| 80.58.61.250/254 | Movistar public DNS |
| 172.23.103.134 | www-60.svc.imagenio.telefonica.net (provisioning) |
| 172.26.83.76/77 | dev-archives.svc.imagenio.telefonica.net (EPG/content) |
| 172.26.82.13/15 | CDN nodes (VOD streaming) |
| 172.23.101.96 | Telemetry/monitoring endpoint (port 9154) |
