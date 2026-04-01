{ network, config, lib, pkgs, ... }:

let
  searchDomainWifiWired = {
    code = 119;
    data = "dhcp.${network.domain}, ${network.domain}, unixpimps.net";
    name = "domain-search";
    space = "dhcp4";
  };

  searchDomainMgnt = {
    code = 119;
    data = "${network.domain}, unixpimps.net";
    name = "domain-search";
    space = "dhcp4";
  };

  searchDomainGuest = {
    code = 119;
    data = "guest.${network.domain}";
    name = "domain-search";
    space = "dhcp4";
  };

  # IPv6 reverse zone name helper for D2 config
  ip6Nibbles = addr:
    let expanded = network.expandIp6 addr;
    in lib.stringToCharacters (lib.replaceStrings [":"] [""] expanded);

  ip6ZoneName = addr:
    let
      nibbles = ip6Nibbles addr;
      rev12 = lib.concatStringsSep "." (lib.reverseList (lib.take 12 nibbles));
    in "${rev12}.ip6.arpa.";

  wiredIp6RevZone = ip6ZoneName "${network.ulaPrefix}:101::1";
  wifiIp6RevZone = ip6ZoneName "${network.ulaPrefix}:100::1";

  # Add SKIP_DDNS class to reservations so static DNS isn't overridden
  skipDdnsReservations = rs: map (r: r // { client-classes = [ "SKIP_DDNS" ]; }) rs;
in
{
  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        authoritative = true;
        hooks-libraries = [{ library = "${pkgs.kea}/lib/kea/hooks/libdhcp_ddns_tuning.so"; parameters = {}; }];
        dhcp-ddns = {
          enable-updates = true;
          server-ip = "127.0.0.1";
          server-port = 53001;
        };
        ddns-override-client-update = true;
        ddns-replace-client-name = "never";
        ddns-update-on-renew = true;
        ddns-ttl-percent = 0.0;
        ddns-conflict-resolution-mode = "no-check-with-dhcid";
        hostname-char-set = "[^A-Za-z0-9.-]";
        hostname-char-replacement = "-";
        client-classes = [
          {
            name = "ubnt";
            option-data = [
              {
                code = 60;
                data = "ubnt";
                name = "vendor-class-identifier";
                space = "dhcp4";
              }
              {
                code = 43;
                name = "vendor-encapsulated-options";
              }
            ];
            option-def = [
              {
                code = 43;
                encapsulate = "ubnt";
                name = "vendor-encapsulated-options";
                type = "empty";
              }
            ];
            test = "substring(option[60].hex,0,4) == 'ubnt'";
          }
          {
            name = "MovistarTV";
            option-data = [
              {
                code = 6;
                data = "172.26.23.3";
                name = "domain-name-servers";
                space = "dhcp4";
              }
              {
                code = 240;
                data = ":::::239.0.2.10:22222:v6.0:239.0.2.30:22222";
                name = "deco240";
                space = "dhcp4";
              }
            ];
            test = "substring(option[60].hex,1,3) == 'IAL'";
          }
          {
            name = "subnet-10.255.100.0-client";
            test = "member('ALL')";
            only-if-required = true;
            option-data = [
              {
                code = 6;
                data = network.hosts.goose.ips.wifi;
                name = "domain-name-servers";
                space = "dhcp4";
              }
            ];
          }
          {
            name = "subnet-10.255.101.0-client";
            test = "member('ALL')";
            only-if-required = true;
            option-data = [
              {
                code = 6;
                data = network.hosts.goose.ips.wired;
                name = "domain-name-servers";
                space = "dhcp4";
              }
            ];
          }
          {
            name = "rpi-pxe";
            test = "option[vendor-class-identifier].text == 'PXEClient:Arch:00000:UNDI:002001'";
            option-data = [
              {
                name = "boot-file-name";
                data = "ipxe-aarch64.efi";
              }
              {
                name = "vendor-class-identifier";
                data = "PXEClient";
              }
              {
                name = "vendor-encapsulated-options";
              }
              {
                name = "PXEBootMenu";
                data = "0,17,Raspberry Pi Boot";
                csv-format = true;
                space = "vendor-encapsulated-options-space";
              }
              {
                name = "PXEDiscoveryControl";
                data = "3";
                csv-format = true;
                space = "vendor-encapsulated-options-space";
              }
              {
                name = "PXEMenuPrompt";
                data = "0,PXE";
                csv-format = true;
                space = "vendor-encapsulated-options-space";
              }
            ];
          }
        ];
        host-reservation-identifiers = [ "hw-address" ];
        interfaces-config = { interfaces = [ "wifi" "wired" "guest" "camera" "mgnt" ]; };
        max-valid-lifetime = 7200;
        option-data = [
          {
            code = 1;
            data = "255.255.255.0";
            name = "subnet-mask";
            space = "dhcp4";
          }
          {
            code = 42;
            data = network.hosts.chronos-wired.ip;
            name = "ntp-servers";
            space = "dhcp4";
          }
        ];
        option-def = [
          {
            code = 240;
            name = "deco240";
            space = "dhcp4";
            type = "string";
          }
          {
            code = 1;
            name = "unifi-address";
            space = "ubnt";
            type = "ipv4-address";
          }
          {
            name = "PXEDiscoveryControl";
            code = 6;
            space = "vendor-encapsulated-options-space";
            type = "uint8";
            array = false;
          }
          {
            name = "PXEMenuPrompt";
            code = 10;
            space = "vendor-encapsulated-options-space";
            type = "record";
            array = false;
            record-types = "uint8,string";
          }
          {
            name = "PXEBootMenu";
            code = 9;
            space = "vendor-encapsulated-options-space";
            type = "record";
            array = false;
            record-types = "uint16,uint8,string";
          }
        ];
        reservations-global = true;
        reservations = skipDdnsReservations network.dhcpReservations;
        subnet4 = [
          {
            id = 1;
            interface = "wifi";
            max-valid-lifetime = 129600;
            ddns-send-updates = true;
            ddns-qualifying-suffix = "dhcp.${network.domain}.";
            option-data = [
              {
                code = 28;
                data = "10.255.100.255";
                name = "broadcast-address";
                space = "dhcp4";
              }
              {
                code = 3;
                data = network.hosts.goose.ips.wifi;
                name = "routers";
                space = "dhcp4";
              }
              {
                code = 1;
                data = network.hosts.cloudkey.ip;
                name = "unifi-address";
                space = "ubnt";
              }
              searchDomainWifiWired
            ];
            pools = [{ pool = "10.255.100.1 - 10.255.100.200"; }];
            subnet = "10.255.100.0/24";
            valid-lifetime = 86400;
            require-client-classes = [
              "subnet-10.255.100.0-client"
            ];
          }
          {
            id = 2;
            interface = "wired";
            max-valid-lifetime = 129600;
            ddns-send-updates = true;
            ddns-qualifying-suffix = "dhcp.${network.domain}.";
            option-data = [
              {
                code = 28;
                data = "10.255.101.255";
                name = "broadcast-address";
                space = "dhcp4";
              }
              {
                code = 3;
                data = network.hosts.goose.ips.wired;
                name = "routers";
                space = "dhcp4";
              }
              {
                code = 1;
                data = network.hosts.cloudkey.ip;
                name = "unifi-address";
                space = "ubnt";
              }
              searchDomainWifiWired
            ];
            pools = [{ pool = "10.255.101.1 - 10.255.101.200"; }];
            subnet = "10.255.101.0/24";
            valid-lifetime = 86400;
            require-client-classes = [
              "subnet-10.255.101.0-client"
            ];
          }
          {
            id = 3;
            interface = "guest";
            max-valid-lifetime = 129600;
            ddns-send-updates = true;
            ddns-qualifying-suffix = "guest.${network.domain}.";
            option-data = [
              {
                code = 28;
                data = "10.255.150.255";
                name = "broadcast-address";
                space = "dhcp4";
              }
              {
                code = 3;
                data = network.hosts.goose.ips.guest;
                name = "routers";
                space = "dhcp4";
              }
              {
                code = 6;
                data = network.hosts.goose.ips.guest;
                name = "domain-name-servers";
                space = "dhcp4";
              }
              searchDomainGuest
            ];
            pools = [{ pool = "10.255.150.1 - 10.255.150.200"; }];
            subnet = "10.255.150.0/24";
            valid-lifetime = 86400;
          }
          {
            id = 4;
            interface = "camera";
            max-valid-lifetime = 129600;
            ddns-send-updates = false;
            option-data = [
              {
                code = 28;
                data = "10.255.200.255";
                name = "broadcast-address";
                space = "dhcp4";
              }
              {
                code = 3;
                data = network.hosts.goose.ips.camera;
                name = "routers";
                space = "dhcp4";
              }
              {
                code = 1;
                data = network.hosts.unvr.ip;
                name = "unifi-address";
                space = "ubnt";
              }
            ];
            pools = [{ pool = "10.255.200.1 - 10.255.200.200"; }];
            subnet = "10.255.200.0/24";
            valid-lifetime = 86400;
          }
          {
            id = 5;
            interface = "mgnt";
            max-valid-lifetime = 129600;
            ddns-send-updates = false;
            option-data = [
              {
                code = 28;
                data = "10.255.254.255";
                name = "broadcast-address";
                space = "dhcp4";
              }
              {
                code = 3;
                data = network.hosts.goose.ips.mgnt;
                name = "routers";
                space = "dhcp4";
              }
              {
                code = 1;
                data = network.hosts.cloudkey.ip;
                name = "unifi-address";
                space = "ubnt";
              }
              {
                code = 6;
                data = network.hosts.goose.ips.mgnt;
                name = "domain-name-servers";
                space = "dhcp4";
              }
              searchDomainMgnt
            ];
            pools = [{ pool = "10.255.254.1 - 10.255.254.200"; }];
            subnet = "10.255.254.0/24";
            valid-lifetime = 86400;
          }
        ];
        valid-lifetime = 600;
      };
    };

    dhcp-ddns = {
      enable = true;
      settings = {
        ip-address = "127.0.0.1";
        port = 53001;
        dns-server-timeout = 3000;
        forward-ddns = {
          ddns-domains = [
            {
              name = "dhcp.${network.domain}.";
              dns-servers = [
                { ip-address = "127.0.0.1"; port = 53; }
              ];
            }
            {
              name = "guest.${network.domain}.";
              dns-servers = [
                { ip-address = "127.0.0.1"; port = 53; }
              ];
            }
          ];
        };
      };
    };
  };

  services.kea.dhcp6 = {
    enable = network.enableIPv6ULA;
    settings = {
      interfaces-config = { interfaces = [ "wired" "wifi" "mgnt" ]; };
      hooks-libraries = [{ library = "${pkgs.kea}/lib/kea/hooks/libdhcp_ddns_tuning.so"; parameters = {}; }];
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp6.leases";
      };
      preferred-lifetime = 86400;
      valid-lifetime = 86400;
      dhcp-ddns = {
        enable-updates = true;
        server-ip = "127.0.0.1";
        server-port = 53001;
      };
      ddns-override-client-update = true;
      ddns-replace-client-name = "never";
      ddns-update-on-renew = true;
      ddns-qualifying-suffix = "dhcp.${network.domain}.";
      hostname-char-set = "[^A-Za-z0-9.-]";
      hostname-char-replacement = "-";
      host-reservation-identifiers = [ "hw-address" ];
      reservations-global = true;
      reservations = skipDdnsReservations network.dhcp6Reservations;
      subnet6 = [
        {
          id = 1;
          interface = "wired";
          subnet = "${network.ulaPrefix}:101::/64";
          pools = [{ pool = "${network.ulaPrefix}:101::1000 - ${network.ulaPrefix}:101::ffff"; }];
          ddns-send-updates = true;
          option-data = [
            {
              name = "dns-servers";
              data = network.hosts.goose.ip6s.wired;
            }
          ];
        }
        {
          id = 2;
          interface = "wifi";
          subnet = "${network.ulaPrefix}:100::/64";
          pools = [{ pool = "${network.ulaPrefix}:100::1000 - ${network.ulaPrefix}:100::ffff"; }];
          ddns-send-updates = true;
          option-data = [
            {
              name = "dns-servers";
              data = network.hosts.goose.ip6s.wifi;
            }
          ];
        }
        {
          id = 3;
          interface = "mgnt";
          subnet = "${network.ulaPrefix}:254::/64";
          pools = [{ pool = "${network.ulaPrefix}:254::1000 - ${network.ulaPrefix}:254::ffff"; }];
          ddns-send-updates = false;
          option-data = [
            {
              name = "dns-servers";
              data = network.hosts.goose.ip6s.mgnt;
            }
          ];
        }
      ];
    };
  };

  services.atftpd = {
    enable = true;
    root = "/srv/tftp";
    extraOptions = [
      "--verbose=7"
    ];
  };

  systemd.services.kea = {
    requires = [ "guest-netdev.service" "mgnt-netdev.service" "wifi-netdev.service" "wired-netdev.service" "camera-netdev.service" ];
  };

  systemd.services.kea-dhcp4-server = {
    bindsTo = [ "network-addresses-wired.service" "network-addresses-wifi.service" ];
    after = [ "network-addresses-wired.service" "network-addresses-wifi.service" ];
  };

  systemd.services.kea-dhcp6-server = {
    bindsTo = [ "network-addresses-wired.service" "network-addresses-wifi.service" "network-addresses-mgnt.service" ];
    after = [ "network-addresses-wired.service" "network-addresses-wifi.service" "network-addresses-mgnt.service" ];
  };

  systemd.services.kea-dhcp-ddns-server = {
    after = [ "hickory-dns.service" ];
    wants = [ "hickory-dns.service" ];
    serviceConfig.ExecStart = lib.mkForce
      "${pkgs.kea}/bin/kea-dhcp-ddns -c ${config.sops.templates."kea-dhcp-ddns.conf".path}";
  };

  sops.templates."kea-dhcp-ddns.conf" = {
    mode = "0444";
    restartUnits = [ "kea-dhcp-ddns-server.service" ];
    content = builtins.toJSON {
      DhcpDdns = {
        ip-address = "127.0.0.1";
        port = 53001;
        dns-server-timeout = 3000;
        tsig-keys = [{
          name = "kea-ddns-key.";
          algorithm = "HMAC-SHA256";
          secret = config.sops.placeholder.hickory_dns_private_key;
        }];
        forward-ddns = {
          ddns-domains = [
            {
              name = "dhcp.${network.domain}.";
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
            {
              name = "guest.${network.domain}.";
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
          ];
        };
        reverse-ddns = {
          ddns-domains = [
            {
              name = "100.255.10.in-addr.arpa.";
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
            {
              name = "101.255.10.in-addr.arpa.";
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
            {
              name = "150.255.10.in-addr.arpa.";
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
            {
              name = wiredIp6RevZone;
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
            {
              name = wifiIp6RevZone;
              key-name = "kea-ddns-key.";
              dns-servers = [{ ip-address = "127.0.0.1"; port = 53; }];
            }
          ];
        };
      };
    };
  };
}
