{ config, pkgs, lib, ... }:

let
  torrent = import ../lib/torrent.nix;
  table = 51820;
in {
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${torrent.wgIP}/32" ];
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
      ${pkgs.iproute2}/bin/ip rule add from ${torrent.wgIP} table ${toString table} priority 100
      ${pkgs.iproute2}/bin/ip rule add to 10.2.0.1/32 table ${toString table} priority 90
    '';
    postShutdown = ''
      ${pkgs.iproute2}/bin/ip rule del from ${torrent.wgIP} table ${toString table} priority 100 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule del to 10.2.0.1/32 table ${toString table} priority 90 2>/dev/null || true
    '';
  };

  networking.nameservers = [ "10.2.0.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ ];
  };
}
