{ config, ... }:

let
  domain = "id.secure.unixpimps.net";
  keycloakPort = 38080;
in
{
  sops.secrets.keycloak_postgresql_password = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

  sops.secrets.keycloak_admin_password = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

  sops.templates."keycloak-bootstrap-admin.env" = {
    content = ''
      KC_BOOTSTRAP_ADMIN_USERNAME=admin
      KC_BOOTSTRAP_ADMIN_PASSWORD=${config.sops.placeholder.keycloak_admin_password}
    '';
    mode = "0400";
    owner = "root";
    group = "root";
    restartUnits = [ "keycloak.service" ];
  };

  services.keycloak = {
    enable = true;

    database = {
      type = "postgresql";
      createLocally = true;

      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_postgresql_password.path;
    };

    settings = {
      hostname = domain;
      http-relative-path = "/";
      http-port = keycloakPort;
      http-host = "127.0.0.1";
      http-enabled = true;
      proxy-headers = "xforwarded";
    };
  };

  systemd.services.keycloak.serviceConfig.EnvironmentFile = [
    config.sops.templates."keycloak-bootstrap-admin.env".path
  ];

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString keycloakPort}";
      proxyWebsockets = true;
    };
  };
}
