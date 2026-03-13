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

    virtualHosts."cctax-proxy.grpc.unixpimps.net" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      extraConfig = ''
        client_max_body_size 64m;
      '';
      locations."/" = {
        extraConfig = ''
          grpc_pass grpc://${network.hosts.cctax-couch.ip}:50051;
          grpc_read_timeout 600s;
          grpc_send_timeout 600s;
          proxy_buffering off;
        '';
      };
    };

    virtualHosts."cloudkey.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "https://${network.hosts.cloudkey.ip}/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_ssl_verify off;
        '';
      };
    };

    virtualHosts."fatty-ipmi.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "https://${network.hosts.fatty-ipmi.ip}/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_ssl_verify off;
        '';
      };
    };

    virtualHosts."goose-ipmi.${network.domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "https://${network.hosts.goose-ipmi.ip}/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_ssl_verify off;
        '';
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
