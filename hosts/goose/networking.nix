{ interfaces, network, lib, pkgs, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.netfilter.nf_conntrack_helper" = 1;
    "net.core.rmem_max" = 268435456;
    "net.core.wmem_max" = 268435456;
    "net.ipv4.tcp_rmem" = "4096 87380 268435456";
    "net.ipv4.tcp_wmem" = "4096 87380 268435456";
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_no_metrics_save" = 1;
    "net.core.netdev_max_backlog" = 250000;
    "net.netfilter.nf_flowtable_udp_timeout" = 30;
  };

  networking = {
    nameservers = [ "127.0.0.1" "8.8.8.8" ];
    search = [ network.domain ];
    dhcpcd.persistent = true;
    vlans = {
      wifi = {
        id = 100;
        interface = "${interfaces.internal}";
      };
      wired = {
        id = 101;
        interface = "${interfaces.internal}";
      };
      guest = {
        id = 150;
        interface = "${interfaces.internal}";
      };
      camera = {
        id = 200;
        interface = "${interfaces.internal}";
      };
      mgnt = {
        id = 254;
        interface = "${interfaces.internal}";
      };
      wan = {
        id = 253;
        interface = "${interfaces.internal}";
      };
      stb = {
        id = 252;
        interface = "${interfaces.internal}";
      };
      mobile = {
        id = 1000;
        interface = "${interfaces.internal}";
      };
    };

    bridges."${interfaces.external}" = {
      interfaces = [ "wan" "stb" ];
    };

    bonds."${interfaces.internal}" = {
      interfaces = interfaces.uplinks;
      driverOptions = {
        mode = "802.3ad";
        miimon = "100";
        downdelay = "200";
        updelay = "200";
        xmit_hash_policy = "layer2+3";
      };
    };

    interfaces = {
      "${interfaces.external}" = {
        ipv4.addresses = [{
          address = "192.168.1.2";
          prefixLength = 24;
        }];
      };
      wifi = {
        ipv4.addresses = [{
          address = network.hosts.goose.ips.wifi;
          prefixLength = 24;
        }];
        ipv6.addresses = lib.optionals network.enableIPv6ULA [{
          address = network.hosts.goose.ip6s.wifi;
          prefixLength = 64;
        }];
      };
      wired = {
        ipv4.addresses = [{
          address = network.hosts.goose.ips.wired;
          prefixLength = 24;
        }];
        ipv6.addresses = lib.optionals network.enableIPv6ULA [{
          address = network.hosts.goose.ip6s.wired;
          prefixLength = 64;
        }];
      };
      guest = {
        ipv4.addresses = [{
          address = network.hosts.goose.ips.guest;
          prefixLength = 24;
        }];
      };
      camera = {
        ipv4.addresses = [{
          address = network.hosts.goose.ips.camera;
          prefixLength = 24;
        }];
      };
      mgnt = {
        ipv4.addresses = [{
          address = network.hosts.goose.ips.mgnt;
          prefixLength = 24;
        }];
        ipv6.addresses = lib.optionals network.enableIPv6ULA [{
          address = network.hosts.goose.ip6s.mgnt;
          prefixLength = 64;
        }];
      };
      mobile = {
        useDHCP = true;
      };
    };
  };

  services.pppd = {
    enable = true;
    peers = {
      movistar = {
        autostart = true;
        enable = true;
        config = ''
                plugin pppoe.so ${interfaces.external}
                name "adslppp@telefonicanetpa"
                password "adslppp"
                persist
                maxfail 0
                holdoff 5
                lcp-echo-failure 5
                lcp-echo-interval 5
                noipdefault
          defaultroute
          defaultroute-metric 0
                replacedefaultroute
          mru 1492
           mtu 1492
                debug
        '';
      };
    };
  };

  environment.etc = {
    "ppp/ip-up.d/10-post-up.sh" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        /run/current-system/sw/bin/nft 'add flowtable ip filter fastnat { devices = { ppp0 }; }'
        /run/current-system/sw/bin/systemctl restart hickory-dns.service
        /run/current-system/sw/bin/systemctl restart prometheus-smokeping-exporter.service
        /run/current-system/sw/bin/systemctl start cloudflare-dyndns.service
      '';
    };
  };

  services.radvd = lib.mkIf network.enableIPv6ULA {
    enable = true;
    config = ''
      interface wired {
        AdvSendAdvert on;
        AdvManagedFlag on;
        AdvOtherConfigFlag on;
        prefix ${network.ulaPrefix}:101::/64 {
          AdvOnLink on;
          AdvAutonomous off;
        };
        RDNSS ${network.hosts.goose.ip6s.wired} {};
      };

      interface wifi {
        AdvSendAdvert on;
        AdvManagedFlag on;
        AdvOtherConfigFlag on;
        prefix ${network.ulaPrefix}:100::/64 {
          AdvOnLink on;
          AdvAutonomous off;
        };
        RDNSS ${network.hosts.goose.ip6s.wifi} {};
      };

      interface mgnt {
        AdvSendAdvert on;
        AdvManagedFlag on;
        AdvOtherConfigFlag on;
        prefix ${network.ulaPrefix}:254::/64 {
          AdvOnLink on;
          AdvAutonomous off;
        };
        RDNSS ${network.hosts.goose.ip6s.mgnt} {};
      };
    '';
  };

  networking.localCommands = ''
    ${pkgs.ethtool}/bin/ethtool -K enp5s0f0np0 hw-tc-offload off 2>/dev/null || true
    ${pkgs.ethtool}/bin/ethtool -K enp5s0f1np1 hw-tc-offload off 2>/dev/null || true
  '';

  services.lldpd.enable = true;
}
