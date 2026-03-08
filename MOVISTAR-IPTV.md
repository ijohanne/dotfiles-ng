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

ACS/TR-069 is **not required** for the STB to boot or function — confirmed by multiple third-party router setups (OPNsense, pfSense, MikroTik, UniFi). The STB only needs DHCP options + DNS + multicast access.

## ACS Block (80.58.63.218)

The Movistar ACS server presents a TLS certificate (issued by PKI SubCA TI TELEFONICA ESP) that the STB firmware rejects with a fatal `bad_certificate` alert (42). This causes the STB to abort boot entirely.

When ACS is **unreachable** (ICMP reject), the STB gracefully skips it and proceeds to boot via Movistar's internal 172.x services. The firewall blocks the STB from reaching ACS to trigger this fallback:

```nix
ip saddr ${network.hosts.livingroom-movistar-stb.ip} ip daddr 80.58.63.218 reject with icmp host-unreachable
```

## Movistar Routes (bird2 RIP v2)

Traffic to Movistar internal networks (172.26.x.x, 172.23.x.x, etc.) must go via the Movistar router (192.168.1.1) on br-wan, not via ppp0. These routes are learned dynamically via RIP v2 from the Movistar router using bird2 (`bird.nix`).

The RIP protocol listens passively on br-wan and imports routes matching `172.16.0.0/12` and `10.0.0.0/8`. This replaces the previous hardcoded static routes in `movistar-routes.service` and the PPP `ip-up.d` script. Bird2 maintains the routes across PPPoE reconnects without needing manual restoration.

Key Movistar internal networks learned via RIP:

| Destination | Purpose |
|---|---|
| 172.26.0.0/17 | IPTV services, DNS (172.26.23.3), EPG, CDN |
| 172.23.0.0/17 | IPTV provisioning, STB services |
| 10.31.255.128/27 | Movistar infrastructure |
| 10.93.18.0/24 | Telefonica PKI servers |

## DHCP Configuration (kea.nix)

The `MovistarTV` client class matches `[IAL]` vendor class and provides:
- **Option 6** (DNS): 172.26.23.3 (Movistar internal DNS)
- **Option 240**: `:::::239.0.2.10:22222:v6.0:239.0.2.30:22222` (multicast discovery config)

The Movistar router's actual DHCP response (captured via br-wan bridge) sends:
- Option 240: `:::::239.0.2.29:22222` (21 bytes, multicast group 239.0.2.29)
- Option 125: GatewayManufacturerOUI=009096, GatewaySerialNumber=C8B422DFC620, GatewayProductClass=RTF8115VW
- DNS: 172.26.23.3 (twice)
- Lease: 12h, IP: 192.168.1.200

**Option 240**: Using the Movistar router's value (239.0.2.29) caused boot failure — STB stuck on service discovery. The working value `:::::239.0.2.10:22222:v6.0:239.0.2.30:22222` was kept.

**Option 125**: Adding this caused both STBs (HUMAX and ARRIS) to reject DHCP offers entirely (Discover→Offer loop, never REQUEST). STBs validate gateway identity in option 125 against the DHCP server. Do not add it.

The STB also requests options 170, 241, 242, 243 — these are not served by either the Movistar router or kea.

**Manual STB fallback**: During boot (5th dot blinking), press the remote's "user" button to manually set OPCH to `239.0.2.30:22222` and DNS to `172.26.23.3`. This bypasses DHCP option 240 entirely.

## Multicast / Live TV

- `igmpproxy` runs with br-wan as upstream, wired/wifi as downstream (IGMPv2 only — required by Movistar)
- NAT prerouting DNAT rules for 172.26.0.0/16 and 172.23.0.0/16 exclude multicast (`ip daddr != 224.0.0.0/4`) to avoid rewriting multicast destinations
- Multicast groups used: 239.0.2.x (service discovery, channels), 239.0.5.x (additional channels)
- IGMP snooping on UniFi switches is NOT the cause of multicast issues (tested with querier switch and with snooping disabled on VLAN 101)

### Known Issue: Live TV Black Screen

STB joins channel multicast groups and data flows at ~12Mbps through goose to wired, but video doesn't display. STB eventually gives up on IGMP entirely. The wired interface has 1.1M TX drops when multicast is active (noqueue qdisc), but changing to fq_codel breaks DHCP. Root cause unresolved.

## VOD (Video on Demand)

VOD uses DASH streaming (no longer RTSP). The flow:

1. STB requests manifest from CDN (172.26.82.15:80)
2. CDN returns **HTTP 302 redirect** to a per-session hostname like `b42190-p1050-h17-v0-*.1.cdn.telefonica.com`
3. STB resolves this hostname — it points to 172.26.82.x (Movistar internal CDN)
4. STB streams DASH segments from the CDN

VOD requires DNS resolution of `cdn.telefonica.com` subdomains. The STB tries both Movistar internal DNS (172.26.23.3) and public Movistar DNS (80.58.61.250/254). When on wired VLAN, public DNS goes via ppp0 — this works.

The `nf_conntrack_rtsp` and `nf_nat_rtsp` kernel modules were removed since Movistar no longer uses RTSP for VOD.

## VLAN 252 Debug Bridge

VLANs 252 (stb) and 253 (wan) are bridged as `br-wan`. To capture STB traffic at L2:

1. Move the STB's switch port to VLAN 252
2. `tcpdump -i br-wan ether host e8:b2:fe:06:a1:28`
3. All traffic between STB and Movistar router flows through goose

PPPoE and the 192.168.1.2 IP are on the bridge interface. This setup is transparent — the STB gets DHCP from the Movistar router (192.168.1.200) and communicates directly at L2.

## Software IPTV Alternative (movistar-u7d)

[movistar-u7d](https://github.com/jmarcet/movistar-u7d) is a Python proxy that converts Movistar multicast IPTV to standard HTTP streams. It provides M3U playlists, XMLTV EPG, and 7-day catchup via flussonic-ts protocol. Actively maintained (last commit Feb 2026).

**Limitation**: Only serves unencrypted TDT (free-to-air) channels. Premium/subscription channels are encrypted and filtered out. Not suitable if you need access to paid Movistar channels.

Supported clients: TiviMate (Android), Kodi + PVR IPTV Simple, UHF (Apple TV, free, supports flussonic catchup), iPlayTV (Apple TV). Does NOT work with Plex (no catchup passthrough) or Infuse (no M3U support).

## Key Movistar IPs

| IP | Role |
|---|---|
| 192.168.1.1 | Movistar ONT/Router (gateway for IPTV networks) |
| 172.26.23.3 | Movistar internal DNS |
| 80.58.63.218 | ACS/TR-069 management server (port 7016/7018) |
| 80.58.61.250/254 | Movistar public DNS |
| 172.23.103.134 | www-60.svc.imagenio.telefonica.net (provisioning) |
| 172.26.83.76/77 | dev-archives.svc.imagenio.telefonica.net (EPG/content) |
| 172.26.82.13/15 | CDN nodes (VOD/DASH streaming) |
| 172.23.101.96 | Telemetry/monitoring endpoint (port 9154) |
