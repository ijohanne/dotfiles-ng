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
              meta oiftype ppp tcp flags syn tcp option maxseg size set 1452 counter comment "ppp mss clamp"
            }

            chain input {
              type filter hook input priority filter; policy drop;
              ct state invalid counter drop comment "invalid state"
              ip saddr 10.0.0.0/8 tcp dport 53 counter accept comment "lan dns tcp"
              ip saddr 10.0.0.0/8 udp dport 53 counter accept comment "lan dns udp"
              ip saddr 10.0.0.0/8 ip protocol icmp counter accept comment "lan icmp"
              iifname { "ppp0", "mobile" } icmp type { destination-unreachable, time-exceeded, parameter-problem, echo-reply } counter accept comment "wan icmp replies"
              iifname { "ppp0", "mobile" } icmp type echo-request limit rate 5/second burst 10 packets counter accept comment "wan ping ratelimit"
              iifname { "ppp0", "mobile" } ip protocol icmp counter drop comment "wan icmp drop"
              ip saddr 0.0.0.0/0 udp dport 51820 counter accept comment "wireguard"

              iifname {
                "wifi",
                "wired",
                "mgnt",
                "${interfaces.external}",
                "lo",
                "wg0"
              } counter accept comment "trusted ifaces"

              iifname "guest" udp dport { 53, 67, 68 } counter accept comment "guest dns+dhcp"
              iifname "guest" tcp dport 53 counter accept comment "guest dns tcp"
              iifname "guest" ct state { established, related } counter accept comment "guest established"
              iifname "guest" counter drop comment "guest drop"

              iifname "camera" udp dport { 53, 67, 68 } counter accept comment "camera dns+dhcp"
              iifname "camera" tcp dport 53 counter accept comment "camera dns tcp"
              iifname "camera" ct state { established, related } counter accept comment "camera established"
              iifname "camera" counter drop comment "camera drop"
              ip protocol igmp counter accept comment "igmp"
              ip saddr 224.0.0.0/4 counter accept comment "multicast"
              iifname "ppp0" ct state { established, related } counter accept comment "wan established"
              iifname "ppp0" counter drop comment "wan drop"
              iifname "mobile" ct state { established, related } counter accept comment "mobile established"
              iifname "mobile" counter drop comment "mobile drop"
              log prefix "nft-input-drop: " counter drop comment "default drop"
            }

            chain forward {
              meta oiftype ppp tcp flags syn tcp option maxseg size set 1452 counter comment "ppp mss clamp"
              type filter hook forward priority filter; policy drop;
              ip protocol { tcp, udp } ct state established flow add @fastnat counter comment "flow offload"
              ct state invalid counter drop comment "invalid state"
              ip saddr ${network.hosts.livingroom-movistar-stb.ip} ip daddr 80.58.63.218 counter reject with icmp host-unreachable comment "stb acs block"
              iifname { "guest", "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } oifname {
                "ppp0", "${interfaces.external}", "mobile"
              } counter accept comment "lan to internet"

              iifname "camera" ip saddr ${network.hosts.unvr.ip} oifname {
                "ppp0", "${interfaces.external}", "mobile"
              } counter accept comment "unvr to internet"

              iifname {
                "ppp0", "${interfaces.external}", "mobile"
              } oifname { "guest", "wifi", "wired", "camera", "mgnt", "${interfaces.external}", "wg0"
              } ct state established,related counter accept comment "wan return"

              iifname { "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } oifname {
                "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } counter accept comment "inter-vlan"

              iifname { "wifi", "wired", "mgnt", "wg0" } oifname "camera" counter accept comment "lan to camera"

              iifname "camera" ip saddr ${network.hosts.unvr.ip} oifname "mgnt" ip daddr {
                ${network.hosts.ap0.ip}, ${network.hosts.ap1.ip},
                ${network.hosts.ap2.ip}, ${network.hosts.ap3.ip}
              } tcp dport 8381 counter accept comment "unvr to aps"

              iifname { "guest", "camera" } oifname "wired" ip daddr ${network.hosts.chronos-wired.ip} udp dport 123 counter accept comment "guest+camera ntp"

              ip saddr 172.26.0.0/16 counter accept comment "movistar iptv 172.26"
              ip saddr 172.23.0.0/16 counter accept comment "movistar iptv 172.23"
              ${dnat.forward}
              log prefix "nft-forward-drop: " counter drop comment "default drop"
            }

            flowtable fastnat {
              hook ingress priority filter
              devices = { ${interfaces.internal} }
            }
        }

        ${if network.enableIPv6ULA then ''
        table ip6 filter {
            chain input {
              type filter hook input priority filter; policy drop;
              ct state invalid counter drop comment "invalid state"
              ip6 saddr fc00::/7 tcp dport 53 counter accept comment "ula dns tcp"
              ip6 saddr fc00::/7 udp dport 53 counter accept comment "ula dns udp"
              ip6 saddr fc00::/7 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit } counter accept comment "ula icmpv6"
              ip6 saddr fc00::/7 udp dport 546 counter accept comment "ula dhcpv6"
              iifname { "wifi", "wired", "mgnt", "${interfaces.external}", "lo", "wg0" } counter accept comment "trusted ifaces"
              iifname "guest" udp dport { 53, 547 } counter accept comment "guest dns+dhcpv6"
              iifname "guest" tcp dport 53 counter accept comment "guest dns tcp"
              iifname "guest" ct state { established, related } counter accept comment "guest established"
              iifname "guest" counter drop comment "guest drop"
              iifname "camera" udp dport { 53, 547 } counter accept comment "camera dns+dhcpv6"
              iifname "camera" tcp dport 53 counter accept comment "camera dns tcp"
              iifname "camera" ct state { established, related } counter accept comment "camera established"
              iifname "camera" counter drop comment "camera drop"
              log prefix "nft-ip6-input-drop: " counter drop comment "default drop"
            }

            chain forward {
              type filter hook forward priority filter; policy drop;
              ct state invalid counter drop comment "invalid state"
              iifname { "ppp0", "mobile" } ip6 nexthdr != 0 counter drop comment "wan ext hdr drop"
              oifname { "ppp0", "mobile" } ip6 nexthdr != 0 counter drop comment "wan ext hdr out drop"
              iifname { "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } oifname { "wifi", "wired", "mgnt", "${interfaces.external}", "wg0" } counter accept comment "inter-vlan"
              iifname { "wifi", "wired", "mgnt", "wg0" } oifname "camera" counter accept comment "lan to camera"
              icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-neighbor-solicit, nd-neighbor-advert } counter accept comment "icmpv6"
              log prefix "nft-ip6-forward-drop: " counter drop comment "default drop"
            }
        }
        '' else ""}

        table ip nat {
            chain prerouting {
              type nat hook prerouting priority -100; policy accept;
              iifname "${interfaces.external}" ip saddr 172.26.0.0/16 ip daddr != 224.0.0.0/4 counter dnat to ${network.hosts.livingroom-movistar-stb.ip} comment "stb iptv 172.26"
              iifname "${interfaces.external}" ip saddr 172.23.0.0/16 ip daddr != 224.0.0.0/4 counter dnat to ${network.hosts.livingroom-movistar-stb.ip} comment "stb iptv 172.23"
              ${dnat.prerouting}
              ${dnat.preroutingLocal}
            }

            chain postrouting {
              type nat hook postrouting priority filter; policy accept;
              oifname "ppp0" counter masquerade comment "ppp0 masquerade"
              oifname "${interfaces.external}" counter masquerade comment "vlan masquerade"
              oifname "mobile" counter masquerade comment "mobile masquerade"
              iifname "wired" oifname "wired" ct status dnat counter masquerade comment "hairpin nat"
            }
        }
      '';
    };
  };
}
