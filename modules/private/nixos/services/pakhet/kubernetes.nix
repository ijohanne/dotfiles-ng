{ network, config, ... }:

{
  services.nginx.virtualHosts."k8s.unixpimps.net" = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
    serverAliases = [ "*.k8s.unixpimps.net" ];
    locations."/" = {
      proxyPass = "https://${network.hosts.k8s-api.ip}/";
      proxyWebsockets = true;
    };
    extraConfig = ''
      allow 10.255.0.0/16;
      deny all;
    '';
  };
}
