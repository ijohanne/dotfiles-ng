{ config, ... }:

{
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cloudflare_api_token.path;
    domains = [
      "r0.est.unixpimps.net"
      "pakhet.est.unixpimps.net"
    ];
    proxied = false;
    ipv4 = true;
    deleteMissing = false;
  };
}
