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

    virtualHosts."cctax-couch.est.unixpimps.net" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://10.255.101.209:5984/";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 4G;
          proxy_buffering off;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
        '';
      };
    };
  };
}
