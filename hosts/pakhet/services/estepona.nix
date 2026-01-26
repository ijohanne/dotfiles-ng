{ ... }:

{
  services.nginx = {
    virtualHosts."printcam.est.unixpimps.net" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://10.255.101.244/webcam/?action=stream";
      };
    };

    virtualHosts."obico.est.unixpimps.net" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://10.255.101.91:3334/";
        proxyWebsockets = true;
      };
    };

    virtualHosts."grafana.est.unixpimps.net" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://10.255.254.254:2342";
      };
    };
  };
}
