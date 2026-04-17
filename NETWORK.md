# Network Architecture

- [Overview](#overview)
- [VLANs & Subnets](#vlans--subnets)
- [Physical Topology](#physical-topology)
  - [Trunk Links](#trunk-links-lacp-aggregates)
  - [WAN Path](#wan-path)
- [Wireless](#wireless)
  - [Access Points](#access-points)
- [Switch Inventory](#switch-inventory)
  - [Cameras](#cameras-vlan-200)
- [How modules/private/inventory/network.nix Works](#how-modulesprivateinventorynetworknix-works)
- [DNS Resolution](#dns-resolution)
- [Adding a New Host](#adding-a-new-host)

## Overview

All network hosts, IPs, and MACs are defined in a single registry at `modules/private/inventory/network.nix`. DNS records, DHCP reservations, and cross-host IP references are derived from this registry.

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
                              │ LACP bond (2x25G SFP28 DAC)
                              │
    ┌─────────────────────────┴─────────────────────────┐
    │       sw10 - USW Pro Aggregation (32-port)        │
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
      Ent24   Agg     Ent8    Ent8   Ent8     Ent8    Pro8
      .167    .1      .170    .171   .174     .169    .166
      │       │       │       │
  p5  ├─sw5 p1└─sw9 p8└─sw3 p1└─sw12
      │ .15     .4      .10     .157
  p6  └─sw6
         .16

    fatty --- sw10 ports 29-30 (2x25G LACP)
               FreeBSD 14.7 server
               bhyve VMs: pakhet, thoth, horus,
                          cctax-node, cctax-couch

    anubis --- Kimsufi dedicated server (OVH Eco, 5.196.77.4)
               NixOS torrent host
               WireGuard backhaul to goose (wg1, 10.100.0.10)
               ProtonVPN P2P tunnel (wg0)
               qBittorrent + nginx + proton-port-sync

    seshat --- Kimsufi dedicated server (OVH Eco, 51.75.118.69)
               NixOS screeny chest counter host
               WireGuard backhaul to goose (wg0, 10.100.0.14)
```

### Trunk Links (LACP Aggregates)

All SFP+ links are 10G single-mode fiber.

```
Link                     Ports (on each side)           Type
──────────────────────────────────────────────────────────────────
goose r0  ↔ sw10         sw10: 31-32                    2x25G SFP28 DAC
sw10      ↔ sw1          sw10: 13-14  │ sw1: 25-26      2x10G SFP+ SM
sw10      ↔ sw7          sw10: 15-18  │ sw7: 5-8        4x10G SFP+ SM
sw10      ↔ sw0          sw10: 19-20  │ sw0: 9-10       2x10G SFP+ SM
sw10      ↔ sw4          sw10: 21-22  │ sw4: 9-10       2x10G SFP+ SM
sw10      ↔ sw11         sw10: 23-24  │ sw11: 9-10      2x10G SFP+ SM
sw10      ↔ sw2          sw10: 25-26  │ sw2: 9-10       2x10G SFP+ SM
sw10      ↔ sw8          sw10: 27-28  │ sw8: 9-10       2x10G SFP+ SM
sw10      ↔ fatty        sw10: 29-30                    2x25G SFP28 DAC
sw7       ↔ sw9          sw7: 1-2     │ sw9: 9-10       2x10G SFP+ SM
sw1       ↔ sw5          sw1: 5       │ sw5: 1          1x1G PoE+ copper
sw1       ↔ sw6          sw1: 6       │ sw6: 1          1x1G PoE+ copper
sw4       ↔ sw3          sw4: 8       │ sw3: 1          1x1G PoE+ copper
sw0       ↔ sw12         sw0: 1       │ sw12: 8         1x1G copper
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
Name   Model           WiFi  Bands           IP        Location
──────────────────────────────────────────────────────────────────────────
ap0    U6 Pro          6     2.4G + 5G       .254.20   Ian's room, sw11 p1
ap1    U6 Pro          6     2.4G + 5G       .254.19   Office, sw1 p2
ap2    U7 Outdoor      7     2.4G + 5G + 6G  .254.165  Terrace, sw4 p5
ap3    U6 Enterprise   6E    2.4G + 5G + 6G  .254.44   Living room, sw0 p8
```

## Switch Inventory

```
Name   Model                   IP        MAC                 PoE   Location / Role
──────────────────────────────────────────────────────────────────────────────────────────
sw10   USW Pro Aggregation     .254.159  ac:8b:a9:67:bf:90   --      Rack, core switch
sw1    USW Enterprise 24 PoE   .254.167  d0:21:f9:8d:c6:9c   PoE+    Rack, access
sw7    USW Aggregation         .254.1    78:45:58:6a:93:78   --      Entrance, access/WAN ingest
sw0    USW Enterprise 8 PoE    .254.171  d0:21:f9:c0:42:8b   PoE+    Living room (TV area), access
sw4    USW Enterprise 8 PoE    .254.170  78:45:58:db:fc:86   PoE+    Indoor terrace, access
sw11   USW Enterprise 8 PoE    .254.174  78:45:58:db:fc:53   PoE+    Ian's room, access
sw2    USW Enterprise 8 PoE    .254.169  78:45:58:dc:05:56   PoE+    Martin's room, access
sw8    USW Pro 8 PoE           .254.166  9c:05:d6:6d:e4:3b   PoE+/++ Kitchen, access
sw9    USW Pro 8 PoE           .254.4    9c:05:d6:6d:d8:e9   PoE+/++ Living room (behind couch), access
sw12   USW Ultra 60W           .254.157  9c:05:d6:ba:08:f5   PoE+    Hallway, printer, access
sw3    USW Flex                .254.10   d0:21:f9:4b:1b:d9   PoE     Outdoor terrace, access
sw5    USW Flex Mini           .254.15   78:45:58:f8:3f:0d   --      Ian's desk, office, access
sw6    USW Flex Mini           .254.16   78:45:58:f8:3f:16   --      Martin's desk, office, access
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

## How `modules/private/inventory/network.nix` Works

The registry contains:

- **`hosts`** — Attrset of all hosts with `ip`, optional `mac`, optional `dns` names, optional `ips` (for multi-IP hosts like goose), and optional `dnat` (port forwarding rules)
- **`extraDns`** — Additional DNS aliases (e.g., `.local` domain entries)

From these, helper functions generate:

| Output              | Used by              | Description                           |
| ------------------- | -------------------- | ------------------------------------- |
| `forwardDns`        | `dns.nix` (unbound)  | Forward A records (local-data)        |
| `reverseDns`        | `dns.nix` (unbound)  | Reverse PTR records (local-data)      |
| `reverseZones`      | `dns.nix` (unbound)  | Reverse zone declarations (local-zone)|
| `dhcpReservations`  | `kea.nix`            | DHCP static leases (hosts with `mac`) |
| `mkDnatRules`       | `firewall.nix`       | DNAT/port-forward nftables rules (hosts with `dnat`) |

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

1. Add an entry to `hosts` in `modules/private/inventory/network.nix`:
   ```nix
   my-host = { ip = "10.255.101.123"; mac = "aa:bb:cc:dd:ee:ff"; };
   ```

2. Optional attributes:
   - `mac` — Adds a DHCP reservation (omit for static-only hosts)
   - `dns` — Override DNS names (default: uses the attribute name)
   - `ips` — Multiple IPs for multi-homed hosts
   - `dnat` — Port forwarding rules (list of `{ proto, port, toPort? }`)

### Port Forwarding (DNAT)

To expose a host's ports to the internet, add a `dnat` attribute:

```nix
my-host = {
  ip = "10.255.101.123"; mac = "aa:bb:cc:dd:ee:ff";
  dnat = [
    { proto = "tcp"; port = 80; }
    { proto = "tcp"; port = 443; }
    { proto = "tcp"; port = 8080; toPort = 80; }  # remap external 8080 → internal 80
  ];
};
```

The `mkDnatRules` helper generates nftables forward-accept, prerouting DNAT, and local DNAT rules from these attributes. `firewall.nix` calls `network.mkDnatRules { extIfaces = ...; }` and interpolates the result.

3. Rebuild affected hosts:
   ```bash
   # On goose (DNS + DHCP)
   sudo nixos-rebuild switch --flake .#goose

   # On pakhet (if the new host is referenced there)
   sudo nixos-rebuild switch --flake .#pakhet
   ```
