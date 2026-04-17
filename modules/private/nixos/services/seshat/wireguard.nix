{ network, config, ... }:

{
  sops.secrets.wireguard_private_key = { };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "${network.hosts.wg-seshat.ip}/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wireguard_private_key.path;

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
}
