{ ... }:

{
  services.privatebin = {
    enable = true;
    enableNginx = true;
    virtualHost = "paste.unixpimps.net";
    settings.main = {
      name = "paste.unixpimps.net";
      discussion = false;
      opendiscussion = false;
    };
  };

  services.nginx.virtualHosts."paste.unixpimps.net" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
  };
}
