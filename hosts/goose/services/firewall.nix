{ interfaces, network, ... }:

let
  dnat = network.mkDnatRules {
    extIfaces = ''{ "ppp0", "${interfaces.external}" }'';
  };
in
{
  networking = {
    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      checkRuleset = false;
      ruleset = ''
        table ip filter {
            chain output {
              type filter hook output priority 100; policy accept;
              meta oiftype ppp tcp flags syn tcp option maxseg size set 1452
            }

            chain input {
              type filter hook input priority filter; policy drop;
              ct state invalid counter drop
              ip saddr 10.0.0.0/8 tcp dport 53 accept;
              ip saddr 10.0.0.0/8 udp dport 53 accept;
              ip saddr 10.0.0.0/8 ip protocol icmp accept
              iifname { "ppp0", "mobile" } icmp type { destination-unreachable, time-exceeded, parameter-problem, echo-reply } accept
              iifname { "ppp0", "mobile" } icmp type echo-request limit rate 5/second burst 10 packets accept
              iifname { "ppp0", "mobile" } ip protocol icmp drop
              ip saddr 0.0.0.0/0 udp dport 51820 accept;

              iifname {
                "wifi",
                "wired",
                "mgnt",
                "${interfaces.external}",
                "lo",
                "wg0"
              } counter accept

              # Guest: DNS + DHCP only
              iifname "guest" udp dport { 53, 67, 68 } accept
              iifname "guest" tcp dport 53 accept
              iifname "guest" ct state { established, related } accept
              iifname "guest" drop

              # Camera: DNS + DHCP only
              iifname "camera" udp dport { 53, 67, 68 } accept
              iifname "camera" tcp dport 53 accept
              iifname "camera" ct state { established, related } accept
              iifname "camera" drop
              ip protocol igmp accept comment "Accept IGMP"
              ip saddr 224.0.0.0/4 accept
              iifname "ppp0" ct state { established, related } counter accept
              iifname "ppp0" drop
              iifname "mobile" ct state { established, related } counter accept
              iifname "mobile" drop
              log prefix "nft-input-drop: " counter drop
            }

            chain forward {
              meta oiftype ppp tcp flags syn tcp option maxseg size set 1452
              type filter hook forward priority filter; policy drop;
              ct state invalid counter drop
              # ACS (80.58.63.218) returns a TLS cert the STB rejects, causing a fatal boot failure.
              # When ACS is unreachable the STB skips it and boots via Movistar internal services.
              ip saddr ${network.hosts.livingroom-movistar-stb.ip} ip daddr 80.58.63.218 reject with icmp host-unreachable
              # LAN/guest → internet
              iifname { "guest", "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } oifname {
                "ppp0", "${interfaces.external}", "mobile"
              } counter accept

              # Camera VLAN: only UNVR gets internet
              iifname "camera" ip saddr ${network.hosts.unvr.ip} oifname {
                "ppp0", "${interfaces.external}", "mobile"
              } accept

              iifname {
                "ppp0", "${interfaces.external}", "mobile"
              } oifname { "guest", "wifi", "wired", "camera", "mgnt", "${interfaces.external}", "wg0"
              } ct state established,related counter accept

              # Trusted inter-VLAN
              iifname { "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } oifname {
                "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } counter accept

              # Trusted → camera (Protect web UI access from LAN)
              iifname { "wifi", "wired", "mgnt", "wg0" } oifname "camera" counter accept

              # Guest/camera → NTP
              iifname { "guest", "camera" } oifname "wired" ip daddr ${network.hosts.chronos-wired.ip} udp dport 123 accept

              ip saddr 172.26.0.0/16 accept
              ip saddr 172.23.0.0/16 accept
              ${dnat.forward}
              log prefix "nft-forward-drop: " counter drop
            }

            flowtable fastnat {
              hook ingress priority filter
              devices = { wifi, wired, camera, mgnt }
            }
        }

        ${if network.enableIPv6ULA then ''
        table ip6 filter {
            chain input {
              type filter hook input priority filter; policy drop;
              ct state invalid counter drop
              ip6 saddr fc00::/7 tcp dport 53 accept
              ip6 saddr fc00::/7 udp dport 53 accept
              ip6 saddr fc00::/7 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit } accept
              ip6 saddr fc00::/7 udp dport 546 accept
              iifname { "wifi", "wired", "mgnt", "${interfaces.external}", "lo", "wg0" } counter accept
              iifname "guest" udp dport { 53, 547 } accept
              iifname "guest" tcp dport 53 accept
              iifname "guest" ct state { established, related } accept
              iifname "guest" drop
              iifname "camera" udp dport { 53, 547 } accept
              iifname "camera" tcp dport 53 accept
              iifname "camera" ct state { established, related } accept
              iifname "camera" drop
              log prefix "nft-ip6-input-drop: " counter drop
            }

            chain forward {
              type filter hook forward priority filter; policy drop;
              ct state invalid counter drop
              iifname { "ppp0", "mobile" } ip6 nexthdr != 0 drop
              oifname { "ppp0", "mobile" } ip6 nexthdr != 0 drop
              iifname { "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } oifname { "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } counter accept
              iifname { "wifi", "wired", "mgnt", "wg0" } oifname "camera" counter accept
              icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-neighbor-solicit, nd-neighbor-advert } accept
              log prefix "nft-ip6-forward-drop: " counter drop
            }
        }
        '' else ""}

        table ip nat {
            chain prerouting {
              type nat hook prerouting priority -100; policy accept;
              iifname "${interfaces.external}" ip saddr 172.26.0.0/16 ip daddr != 224.0.0.0/4 dnat to ${network.hosts.livingroom-movistar-stb.ip}
              iifname "${interfaces.external}" ip saddr 172.23.0.0/16 ip daddr != 224.0.0.0/4 dnat to ${network.hosts.livingroom-movistar-stb.ip}
              ${dnat.prerouting}
              ${dnat.preroutingLocal}
            }

            chain postrouting {
              type nat hook postrouting priority filter; policy accept;
              oifname "ppp0" masquerade
              oifname "${interfaces.external}" masquerade
              oifname "mobile" masquerade
              iifname "wired" oifname "wired" ct status dnat masquerade
            }
        }
      '';
    };
  };
}
