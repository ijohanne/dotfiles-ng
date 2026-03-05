{ interfaces, network, ... }:

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
              ip saddr 10.0.0.0/8 tcp dport 53 accept;
              ip saddr 10.0.0.0/8 udp dport 53 accept;
              ip saddr 0.0.0.0/0 tcp dport 25 accept;
              ip protocol icmp accept;
              ip saddr 0.0.0.0/0 udp dport 51820 accept;

              iifname {
                "wifi",
                "wired",
                "mgnt",
                "guest",
                "camera",
                "${interfaces.external}",
                "lo",
                "wg0"
              } counter accept
              ip protocol igmp accept comment "Accept IGMP"
              ip saddr 224.0.0.0/4 accept
              iifname "ppp0" ct state { established, related } counter accept
              iifname "ppp0" drop
              iifname "mobile" ct state { established, related } counter accept
              iifname "mobile" drop
            }

            chain forward {
              meta oiftype ppp tcp flags syn tcp option maxseg size set 1452
              type filter hook forward priority filter; policy drop;
              ip protocol { tcp , udp } flow offload @fastnat;
              iifname { "guest", "wifi", "wired", "camera", "mgnt", "${interfaces.external}", "wg0" } oifname {
                "ppp0", "${interfaces.external}", "mobile"
              } counter accept

              iifname {
                "ppp0", "${interfaces.external}", "mobile"
              } oifname { "guest", "wifi", "wired", "camera", "mgnt", "${interfaces.external}", "wg0"
              } ct state established,related counter accept

              iifname { "wifi", "wired", "camera", "mgnt", "${interfaces.external}", "wg0" } oifname {
                "wifi", "wired", "camera", "mgnt", "${interfaces.external}", "wg0" } counter accept

              ip saddr 172.26.0.0/16 accept
              ip saddr 172.23.0.0/16 accept
              meta iifname { "ppp0", "wan" }  meta oif "wired" ip daddr ${network.hosts.pakhet.ip} tcp dport { 80, 443 } ct state new accept
              meta iifname { "ppp0", "wan" }  meta oif "wired" ip daddr ${network.hosts.cctax-node.ip} tcp dport { 8888, 20000 } ct state new accept
            }

            flowtable fastnat {
              hook ingress priority filter
              devices = { wifi, wired, camera, mgnt, ${interfaces.external} }
            }
        }

        table ip nat {
            chain prerouting {
              type nat hook prerouting priority -100; policy accept;
              iifname "${interfaces.external}" ip saddr 172.26.0.0/16 dnat to ${network.hosts.livingroom-movistar-stb.ip}
              iifname "${interfaces.external}" ip saddr 172.23.0.0/16 dnat to ${network.hosts.livingroom-movistar-stb.ip}
              meta iifname { "ppp0", "wan" }  tcp dport { 80, 443 } dnat ${network.hosts.pakhet.ip};
              tcp dport { 80, 443 } fib daddr type local dnat ip to ${network.hosts.pakhet.ip};
              meta iifname { "ppp0", "wan" }  tcp dport { 8888, 20000 } dnat ${network.hosts.cctax-node.ip};
              tcp dport { 8888, 20000 } fib daddr type local dnat ip to ${network.hosts.cctax-node.ip};
            }

            chain postrouting {
              type nat hook postrouting priority filter; policy accept;
              oifname "ppp0" masquerade
              oifname "${interfaces.external}" masquerade
              oifname "mobile" masquerade
              oifname { "wifi", "wired", "camera", "mgmt" }
            }
        }
      '';
    };
  };
}
