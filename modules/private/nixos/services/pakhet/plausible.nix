{ config, ... }:

{
  services.plausible = {
    enable = true;

    server = {
      baseUrl = "https://analytics.unixpimps.net";
      port = 8000;
      secretKeybaseFile = config.sops.secrets.plausible_secret_key_base.path;
      disableRegistration = true;
    };

    mail = {
      email = "no-reply@unixpimps.net";
      smtp = {
        hostAddr = "pakhet.est.unixpimps.net";
        hostPort = 25;
      };
    };
  };

  services.nginx.virtualHosts."analytics.unixpimps.net" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8000";
      proxyWebsockets = true;
    };
  };
}
