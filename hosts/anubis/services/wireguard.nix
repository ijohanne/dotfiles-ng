{ network, ... }:

{ config, pkgs, ... }:

let
  wgIP = "10.2.0.2";
  table = 51820;
in {
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "${wgIP}/32" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."protonvpn/private_key".path;
      table = toString table;

      peers = [
        {
          publicKey = "D8Sqlj3TYwwnTkycV08HAlxcXXS3Ura4oamz8rB5ImM=";
          endpoint = "103.69.224.4:51820";
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          persistentKeepalive = 25;
        }
      ];

      postSetup = ''
        ${pkgs.iproute2}/bin/ip rule add from ${wgIP} table ${toString table} priority 100
        ${pkgs.iproute2}/bin/ip rule add to 10.2.0.1/32 table ${toString table} priority 90
      '';
      postShutdown = ''
        ${pkgs.iproute2}/bin/ip rule del from ${wgIP} table ${toString table} priority 100 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip rule del to 10.2.0.1/32 table ${toString table} priority 90 2>/dev/null || true
      '';
    };

    wg1 = {
      ips = [ "${network.hosts.wg-anubis.ip}/24" ];
      listenPort = 51821;
      privateKeyFile = config.sops.secrets."backhaul/private_key".path;

      peers = [
        {
          publicKey = "K+hCH4RUeaJDvRYrEKtDe577ocMZ573ARhgjgKQOZg8=";
          allowedIPs = [ "10.100.0.0/24" "10.255.0.0/16" ];
          endpoint = "r0.est.unixpimps.net:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  networking.nameservers = [ "10.2.0.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ ];
  };
}
