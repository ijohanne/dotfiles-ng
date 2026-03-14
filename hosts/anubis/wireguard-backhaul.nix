{ network, ... }:

{ config, ... }:

{
  networking.wireguard.interfaces.wg1 = {
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
}
