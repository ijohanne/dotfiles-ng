{ network, ... }:

{
  services.nginx = {
    virtualHosts."printcam.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://${network.hosts.sobek-wired.ip}/webcam/?action=stream";
      };
    };

    virtualHosts."obico.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://${network.hosts.obico.ip}:3334/";
        proxyWebsockets = true;
      };
    };

    virtualHosts."grafana.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://${network.hosts.goose.ips.mgnt}:2342";
      };
    };

    virtualHosts."cctax-couch.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://${network.hosts.cctax-couch.ip}:5984/";
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
