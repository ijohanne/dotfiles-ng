# Network Architecture

## Overview

All network hosts, IPs, and MACs are defined in a single registry at `configs/network.nix`. DNS records, DHCP reservations, and cross-host IP references are derived from this registry.

## VLANs & Subnets

```
VLAN  Subnet            Gateway          Purpose
─────────────────────────────────────────────────────
  35  10.255.35.0/24    10.255.35.254    Default (UniFi mgmt)
 100  10.255.100.0/24   10.255.100.254   WiFi clients
 101  10.255.101.0/24   10.255.101.254   Wired clients
 150  10.255.150.0/24   10.255.150.254   Guest network
 200  10.255.200.0/24   10.255.200.254   Cameras
 252  (STB VLAN)                         Movistar set-top box
 253  (WAN VLAN)                         ISP uplink (PPPoE)
 254  10.255.254.0/24   10.255.254.254   Management
1000  (Mobile VLAN)                      Mobile/cellular backup
```

All gateway IPs belong to **goose** (the router). They are defined in `network.hosts.goose.ips`.

## Physical Topology

Site: **Estepona, Spain** — domain `est.es.unixpimps.net`

```
                         ISP (Movistar PPPoE)
                              │ VLAN 253
                              │
    ┌─────────────────────────┴─────────────────────────┐
    │             goose (r0) - NixOS router             │
    │             10.255.254.254 (mgnt)                 │
    └─────────────────────────┬─────────────────────────┘
                              │ LACP bond (2x25G SFP28)
                              │
    ┌─────────────────────────┴─────────────────────────┐
    │       sw10 - Pro Max Aggregation (32-port)        │
    │       10.255.254.159   ac:8b:a9:67:bf:90          │
    │                                                   │
    │  Core aggregation - all trunks terminate here.    │
    │  10G SFP+ uplinks to every distribution switch.   │
    └───────────────────────┬───────────────────────────┘
                            │
      p13-14  p15-18  p21-22  p19-20  p23-24  p25-26  p27-28
        ┌───────┬───────┬───┴───┬───────┬───────┬───────┐
        │       │       │       │       │       │       │
      sw1     sw7     sw4     sw0    sw11     sw2     sw8
     24PoE    Agg    8PoE   8PoE   8PoE    8PoE    8PoE
     .167     .1      .170   .171   .174    .169    .166
      │       │       │       │
  p5  ├─sw5 p1└─sw9 p8└─sw3 p1└─sw12
      │ .15     .4      .10     .157
  p6  └─sw6
         .16

    fatty --- sw10 ports 29-30 (2x25G LACP)
               FreeBSD 14.7 server
               bhyve VMs: pakhet, thoth, horus,
                          cctax-node, cctax-couch
```

### Trunk Links (LACP Aggregates)

```
Link                     Ports (on each side)           Type
──────────────────────────────────────────────────────────────
goose r0  ↔ sw10         sw10: 31-32                    2x25G SFP28
sw10      ↔ sw1          sw10: 13-14  │ sw1: 25-26      2xSFP+
sw10      ↔ sw7          sw10: 15-18  │ sw7: 5-8        4xSFP+
sw10      ↔ sw0          sw10: 19-20  │ sw0: 9-10       2xSFP+
sw10      ↔ sw4          sw10: 21-22  │ sw4: 9-10       2xSFP+
sw10      ↔ sw11         sw10: 23-24  │ sw11: 9-10      2xSFP+
sw10      ↔ sw2          sw10: 25-26  │ sw2: 9-10       2xSFP+
sw10      ↔ sw8          sw10: 27-28  │ sw8: 9-10       2xSFP+
sw10      ↔ fatty        sw10: 29-30                    2x25G SFP28
sw7       ↔ sw9          sw7: 1-2     │ sw9: 9-10       2xSFP+
sw1       ↔ sw5          sw1: 5       │ sw5: 1          1xPoE
sw1       ↔ sw6          sw1: 6       │ sw6: 1          1xPoE
sw4       ↔ sw3          sw4: 8       │ sw3: 1          1xPoE
sw0       ↔ sw12         sw0: 1       │ sw12: 8         1x
```

### WAN Path

The Movistar router (in passthrough mode) is on a different floor.
It connects to sw7 port 4, which tags it on VLAN 253. That VLAN is
trunked through sw7 -> sw10 -> goose alongside all other VLANs,
so goose can speak PPPoE directly to the Movistar router.

```
Movistar router ---- sw7 port 4 (VLAN 253 + 252)
  (passthrough)         │
                        │ trunk (4xSFP+)
                        │
                      sw10 ---- goose (PPPoE on VLAN 253)
                                       (STB on VLAN 252)
```

## Wireless

```
SSID                 Band        VLAN    Security
──────────────────────────────────────────────────
UNIXPIMPSNET         2.4 GHz     100     WPA2-PSK
UNIXPIMPSNET_5Ghz    5 GHz       100     WPA2-PSK
UNIXPIMPSNET_6Ghz    6 GHz       100     WPA2-PSK
UNIXPIMPSNET_GUEST   all         150     WPA2-PSK
```

### Access Points

```
Name   Model              IP              Location
─────────────────────────────────────────────────────────
ap0    U6 Mesh Pro        .254.20         Uplink via sw11
ap1    U6 Mesh Pro        .254.19         Uplink via sw1 port 2
ap2    U7 Outdoor         .254.165        Uplink via sw4 port 5 (terrace)
ap3    U6 Enterprise      .254.44         Uplink via sw0 port 8 (living room)
```

## Switch Inventory

```
Name   Model                    IP              MAC                 PoE    Location / Role
───────────────────────────────────────────────────────────────────────────────────────────────
sw10   Pro Max Aggregation      .254.159        ac:8b:a9:67:bf:90   —      Core aggregation
sw1    Switch Pro 24 PoE        .254.167        d0:21:f9:8d:c6:9c   PoE+   Office / server rack
sw7    USW Aggregation           .254.1          78:45:58:6a:93:78   —      WAN demarcation (other floor)
sw0    Switch Lite 8 PoE        .254.171        d0:21:f9:c0:42:8b   PoE    Living room
sw4    Switch Lite 8 PoE        .254.170        78:45:58:db:fc:86   PoE    Terrace / outdoor
sw11   Switch Lite 8 PoE        .254.174        78:45:58:db:fc:53   PoE    Bedroom media
sw2    Switch Lite 8 PoE        .254.169        78:45:58:dc:05:56   PoE    Spare / expansion
sw8    Lite 8 PoE               .254.166        9c:05:d6:6d:e4:3b   PoE    Kitchen area
sw9    Lite 8 PoE               .254.4          9c:05:d6:6d:d8:e9   PoE    Living room cameras
sw12   Pro Max Mini 8 PoE       .254.157        9c:05:d6:ba:08:f5   PoE    Kitchen hallway
sw3    Flex Mini 5 PoE          .254.10         d0:21:f9:4b:1b:d9   PoE    Terrace cameras
sw5    Flex Mini                .254.15         78:45:58:f8:3f:0d   —      Office desk
sw6    Flex Mini                .254.16         78:45:58:f8:3f:16   —      Guest / office
```

## Notable Wired Clients (from port labels)

```
Device               Switch  Port  VLAN       Notes
────────────────────────────────────────────────────────────────
Cloud Key            sw1     1     MGNT       UniFi controller, PoE
PiKVM3               sw1     3     MGNT       KVM-over-IP
IPMI fatty           sw1     7     MGNT       Server IPMI
IPMI r0              sw1     10    MGNT       Router IPMI
KVM switch           sw1     9     MGNT       Physical KVM, PoE
IJ (workstation)     sw10    1     WIRED      10G
MKJ (workstation)    sw10    2     WIRED      10G
fatty (server)       sw10    29-30 WIRED      2x25G LACP
sobek                sw1     13    WIRED      PoE
hapi                 sw1     14    WIRED      PoE
Prusa MK4            sw1     12    WIRED      3D printer, PoE
chronos              sw4     3     WIRED      PoE
Gardena              sw4     2     WIRED      Smart irrigation, PoE
nvr-00-00            sw10    12    CAMERA     NVR
PlayStation 5        sw0     4     WIRED
Movistar STB         sw0     5     STB (252)
AppleTV (living)     sw0     6     WIRED
AppleTV (bedroom)    sw11    7     WIRED
Sonos Amp            sw1     11    WIRED      Office
Sonos Beam           sw0     2     WIRED      Living room
Sonos Sub            sw0     3     WIRED      Living room
Sonos Terrace        sw4     1     WIRED      PoE
```

### Cameras (VLAN 200)

```
Camera               Switch  Port  Notes
────────────────────────────────────────────────
Terrace west-south   sw3     2     PoE
Terrace west-east    sw3     3     PoE
Terrace door         sw3     4     PoE
Terrace east         sw4     4     PoE
Indoor terrace       sw4     6     PoE
Office               sw1     8     PoE
Hallway office       sw1     4     PoE
Hallway kitchen      sw12    1     PoE
Kitchen              sw8     3     PoE
Living room          sw9     1     PoE
Entrance             sw9     2     PoE
```

## How `configs/network.nix` Works

The registry contains:

- **`hosts`** — Attrset of all hosts with `ip`, optional `mac`, optional `dns` names, and optional `ips` (for multi-IP hosts like goose)
- **`extraDns`** — Additional DNS aliases (e.g., `.local` domain entries)

From these, helper functions generate:

| Output              | Used by              | Description                           |
| ------------------- | -------------------- | ------------------------------------- |
| `forwardDns`        | `dns.nix` (unbound)  | Forward A records (local-data)        |
| `reverseDns`        | `dns.nix` (unbound)  | Reverse PTR records (local-data)      |
| `reverseZones`      | `dns.nix` (unbound)  | Reverse zone declarations (local-zone)|
| `dhcpReservations`  | `kea.nix`            | DHCP static leases (hosts with `mac`) |

Cross-host references use `network.hosts.<name>.ip` directly (e.g., firewall rules, nginx proxy_pass, prometheus targets).

## DNS Resolution

```
Client query
    │
    ▼
 unbound (goose)
    │
    ├─ local-data match? → return A/PTR record
    │   (all registry hosts + extraDns)
    │
    └─ no match → recursive resolution upstream
        │
        ├─ est.unixpimps.net → Cloudflare (public records like grafana)
        └─ everything else → root servers
```

No `local-zone` is set for `est.unixpimps.net` — only `local-data`. This means unbound serves LAN-only records locally while forwarding unknown subdomains upstream to Cloudflare.

Reverse zones (`in-addr.arpa`) use `local-zone: static` since private IPs never resolve upstream.

## Adding a New Host

1. Add an entry to `hosts` in `configs/network.nix`:
   ```nix
   my-host = { ip = "10.255.101.123"; mac = "aa:bb:cc:dd:ee:ff"; };
   ```

2. Optional attributes:
   - `mac` — Adds a DHCP reservation (omit for static-only hosts)
   - `dns` — Override DNS names (default: uses the attribute name)
   - `ips` — Multiple IPs for multi-homed hosts

3. Rebuild affected hosts:
   ```bash
   # On goose (DNS + DHCP)
   sudo nixos-rebuild switch --flake .#goose

   # On pakhet (if the new host is referenced there)
   sudo nixos-rebuild switch --flake .#pakhet
   ```
