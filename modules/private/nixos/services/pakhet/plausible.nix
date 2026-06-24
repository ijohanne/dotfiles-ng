{ config, lib, ... }:

let
  plausibleProxyVhost = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8000";
      proxyWebsockets = true;
    };
  };

  plausibleDns01ProxyVhost = plausibleProxyVhost // {
    acmeRoot = null;
  };

  plausibleHttp01ProxyVhost = plausibleProxyVhost // {
    acmeRoot = "/var/lib/acme/acme-challenge";
  };
in
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
        hostPort = 465;
        user = "no-reply@unixpimps.net";
        passwordFile = config.sops.secrets.mail_password_no_reply.path;
        enableSSL = true;
      };
    };
  };

  services.nginx.virtualHosts = lib.genAttrs [
    "analytics.unixpimps.net"
    "analytics.opsplaza.com"
    "analytics.mathxp.app"
    "analytics.volahealth.com"
    "analytics.beevpn.com"
  ]
    (_: plausibleDns01ProxyVhost)
  // {
    "analytics.biohackerofficial.com" = plausibleHttp01ProxyVhost;
  };

  security.acme.certs."analytics.biohackerofficial.com" = {
    inheritDefaults = false;
    email = config.security.acme.defaults.email;
  };
}
