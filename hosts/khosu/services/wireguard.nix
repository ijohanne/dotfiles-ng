{ config, ... }:

{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.8/24" ];
      privateKeyFile = "/run/secrets/wireguard_private_key";

      peers = [
        {
          # goose (gateway)
          publicKey = "K+hCH4RUeaJDvRYrEKtDe577ocMZ573ARhgjgKQOZg8=";
          allowedIPs = [ "10.100.0.0/24" "10.255.0.0/16" ];
          endpoint = "r0.est.unixpimps.net:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
