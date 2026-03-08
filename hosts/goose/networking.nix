{ interfaces, ... }:

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
  };

  networking = {
    nameservers = [ "127.0.0.1" "8.8.8.8" ];
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
      mobile = {
        id = 1000;
        interface = "${interfaces.internal}";
      };
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
          address = "10.255.100.254";
          prefixLength = 24;
        }];
      };
      wired = {
        ipv4.addresses = [{
          address = "10.255.101.254";
          prefixLength = 24;
        }];
      };
      guest = {
        ipv4.addresses = [{
          address = "10.255.150.254";
          prefixLength = 24;
        }];
      };
      camera = {
        ipv4.addresses = [{
          address = "10.255.200.254";
          prefixLength = 24;
        }];
      };
      mgnt = {
        ipv4.addresses = [{
          address = "10.255.254.254";
          prefixLength = 24;
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
        /run/current-system/sw/bin/ip route replace 172.26.0.0/17 via 192.168.1.1 dev ${interfaces.external}
        /run/current-system/sw/bin/ip route replace 172.23.0.0/17 via 192.168.1.1 dev ${interfaces.external}
        /run/current-system/sw/bin/ip route replace 10.31.255.128/27 via 192.168.1.1 dev ${interfaces.external}
        /run/current-system/sw/bin/ip route replace 10.93.18.0/24 via 192.168.1.1 dev ${interfaces.external}
        /run/current-system/sw/bin/systemctl restart unbound.service
        /run/current-system/sw/bin/systemctl restart prometheus-smokeping-exporter.service
        /run/current-system/sw/bin/systemctl start cloudflare-dyndns.service
      '';
    };
  };

  systemd.services.movistar-routes = {
    description = "Movistar static routes via wan";
    after = [ "network-addresses-${interfaces.external}.service" ];
    requires = [ "network-addresses-${interfaces.external}.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = let ip = "/run/current-system/sw/bin/ip"; in [
        "${ip} route replace 172.26.0.0/17 via 192.168.1.1 dev ${interfaces.external}"
        "${ip} route replace 172.23.0.0/17 via 192.168.1.1 dev ${interfaces.external}"
        "${ip} route replace 10.31.255.128/27 via 192.168.1.1 dev ${interfaces.external}"
        "${ip} route replace 10.93.18.0/24 via 192.168.1.1 dev ${interfaces.external}"
      ];
    };
  };

  services.lldpd.enable = true;
}
