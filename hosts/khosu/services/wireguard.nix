{ network, ... }:

{ config, ... }:

{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "${network.hosts.wg-khosu.ip}/24" ];
      privateKeyFile = "/run/secrets/wireguard_private_key";

      peers = [
        {
          # goose (gateway) — route all WG peers + LAN through goose
          publicKey = "K+hCH4RUeaJDvRYrEKtDe577ocMZ573ARhgjgKQOZg8=";
          allowedIPs = [ "10.100.0.0/24" "10.255.0.0/16" ];
          endpoint = "r0.est.unixpimps.net:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
