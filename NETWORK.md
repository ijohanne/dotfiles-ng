# Network Architecture

## Overview

All network hosts, IPs, and MACs are defined in a single registry at `configs/network.nix`. DNS records, DHCP reservations, and cross-host IP references are derived from this registry.

## VLANs & Subnets

```
VLAN  Subnet            Gateway          Purpose
─────────────────────────────────────────────────────
100   10.255.100.0/24   10.255.100.254   WiFi clients
101   10.255.101.0/24   10.255.101.254   Wired clients
150   10.255.150.0/24   10.255.150.254   Guest network
200   10.255.200.0/24   10.255.200.254   Cameras
254   10.255.254.0/24   10.255.254.254   Management
253   (WAN VLAN)                         ISP uplink
```

All gateway IPs belong to **goose** (the router). They are defined in `network.hosts.goose.ips`.

## Topology

```
                     ISP (PPPoE)
                        │
                    ┌───┴───┐
                    │ goose │  NixOS router/firewall
                    │  r0   │  10.255.254.254 (mgnt)
                    └───┬───┘
                        │ trunk (bond0, LACP)
                    ┌───┴───┐
                    │  USW  │  UniFi switches
                    └───┬───┘
           ┌────────┬───┴───┬────────┐
           │        │       │        │
        WiFi(100) Wired(101) Cam(200) Mgnt(254)
           │        │       │        │
      clients   servers   cameras  cloudkey
                 pakhet              UNVR
                 fatty
                 k8s-*
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
