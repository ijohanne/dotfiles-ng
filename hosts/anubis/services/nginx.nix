{ network, config, pkgs, lib, ... }:

let
  allowedRanges = [
    "10.255.0.0/16"
    "10.100.0.0/24"
  ];
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = "sysops@unixpimps.net";
    defaults = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets."acme/cloudflare_api_key".path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;

    virtualHosts."wg-anubis.est.unixpimps.net" = {
      listen = [
        { addr = network.hosts.wg-anubis.ip; port = 443; ssl = true; }
      ];

      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      extraConfig = ''
        ${lib.concatMapStringsSep "\n" (range: "allow ${range};") allowedRanges}
        deny all;
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };

      locations."/files" = {
        extraConfig = ''
          rewrite ^/files$ /files/ last;
        '';
      };

      locations."/files/" = {
        alias = "/data/torrents/complete/";
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
  };

  users.users.nginx.extraGroups = [ "qbittorrent" ];
}
