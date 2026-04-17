{ config, lib, ... }:

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
    wantedBy = lib.mkForce [ ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
      RestartSteps = 10;
      RestartMaxDelaySec = "5min";
    };
  };
}
