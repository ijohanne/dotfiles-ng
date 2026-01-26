{ ... }:

{
  services.nginx.virtualHosts."k8s.unixpimps.net" = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
    serverAliases = [ "*.k8s.unixpimps.net" ];
    locations."/" = {
      proxyPass = "https://10.255.240.1/";
      proxyWebsockets = true;
    };
    extraConfig = ''
      allow 10.255.0.0/16;
      deny all;
    '';
  };
}
