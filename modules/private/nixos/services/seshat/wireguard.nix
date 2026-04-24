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
          allowedIPs = [
            "10.100.0.0/24"
            "10.255.0.0/16"
          ];
          endpoint = "r0.est.unixpimps.net:51820";
          persistentKeepalive = 25;
        }
      ];
    };

    wg-ops = {
      ips = [ "${network.hosts.wg-seshat-ops.ip}/32" ];
      listenPort = 51821;
      privateKeyFile = config.sops.secrets.wireguard_private_key.path;

      peers = [
        {
          publicKey = "7l0WgmtS4C/Sk8Pn/UeXKrLqVxU3sRHCxzPeA1wmzEs=";
          allowedIPs = [ "172.29.89.1/32" ];
          endpoint = "54.36.120.51:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
