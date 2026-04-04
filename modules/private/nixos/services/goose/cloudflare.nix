{ config, ... }:

{
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cloudflare_api_token.path;
    domains = [
      "r0.est.unixpimps.net"
    ];
    proxied = false;
    ipv4 = true;
    deleteMissing = false;
  };

  systemd.services.cloudflare-dyndns = {
    after = [ "hickory-dns.service" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
      RestartMaxDelaySec = "5min";
    };
  };
}
