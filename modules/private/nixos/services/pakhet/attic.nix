{ config, pkgs, ... }:

let
  atticApiHost = "nix-cache.unixpimps.net";
  atticBootstrapCache = "ijohanne";
  atticClient = "${pkgs.attic-client}/bin/attic";

  atticEnv = config.sops.templates."atticd-env";

  atticBootstrap = pkgs.writeShellScript "attic-bootstrap" ''
    set -euo pipefail

    state_root=/var/lib/attic-bootstrap
    export HOME="$state_root"
    export XDG_CONFIG_HOME="$state_root/xdg"

    rm -rf "$XDG_CONFIG_HOME"
    mkdir -p "$XDG_CONFIG_HOME"

    token=$(/run/current-system/sw/bin/atticd-atticadm make-token \
      --sub bootstrap \
      --validity '10 years' \
      --pull '*' \
      --push '*' \
      --delete '*' \
      --create-cache '*' \
      --configure-cache '*' \
      --configure-cache-retention '*' \
      --destroy-cache '*')

    ${atticClient} login bootstrap http://127.0.0.1:8080/ "$token"

    if ! ${atticClient} cache info bootstrap:${atticBootstrapCache} >/dev/null 2>&1; then
      ${atticClient} cache create bootstrap:${atticBootstrapCache} --public
    fi

    ${atticClient} cache configure bootstrap:${atticBootstrapCache} --public
    ${atticClient} cache info bootstrap:${atticBootstrapCache} > "$state_root/${atticBootstrapCache}.info"
  '';
in
{
  sops.secrets.attic_token_rs256_secret_base64 = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

  sops.templates."atticd-env" = {
    content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder.attic_token_rs256_secret_base64}
      AWS_ACCESS_KEY_ID=${config.sops.placeholder.garage_attic_key_id}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.garage_attic_secret_key}
    '';
    mode = "0400";
    owner = "root";
    group = "root";
  };

  services.postgresql.ensureDatabases = [ "atticd" ];
  services.postgresql.ensureUsers = [
    {
      name = "atticd";
      ensureDBOwnership = true;
    }
  ];

  services.atticd = {
    enable = true;
    package = pkgs.attic-server;
    environmentFile = atticEnv.path;
    settings = {
      listen = "127.0.0.1:8080";
      allowed-hosts = [
        atticApiHost
        "${atticBootstrapCache}.${atticApiHost}"
        "127.0.0.1:8080"
        "localhost:8080"
      ];
      api-endpoint = "https://${atticApiHost}/";
      substituter-endpoint = "https://${atticApiHost}/";

      database.url = "postgres:///atticd?host=/run/postgresql&user=atticd";

      storage = {
        type = "s3";
        region = "garage";
        bucket = "attic";
        endpoint = "https://s3.unixpimps.net";
      };
    };
  };

  security.acme.certs.${atticApiHost} = {
    extraDomainNames = [ "*.${atticApiHost}" ];
    group = config.services.nginx.group;
  };

  services.nginx.virtualHosts.${atticApiHost} = {
    forceSSL = true;
    useACMEHost = atticApiHost;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      extraConfig = ''
        client_max_body_size 0;
        proxy_request_buffering off;
        proxy_buffering off;
      '';
    };
  };

  services.nginx.virtualHosts."~^(?<cache>[a-z0-9][a-z0-9-]*)\\.nix-cache\\.unixpimps\\.net$" = {
    forceSSL = true;
    useACMEHost = atticApiHost;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      extraConfig = ''
        client_max_body_size 0;
        proxy_request_buffering off;
        proxy_buffering off;
        rewrite ^/(.*)$ /$cache/$1 break;
        proxy_set_header Host ${atticApiHost};
      '';
    };
  };

  systemd.services.atticd = {
    after = [ "garage-bootstrap.service" ];
    requires = [ "garage-bootstrap.service" ];
  };

  systemd.services.attic-bootstrap = {
    description = "Bootstrap the initial public Attic cache";
    wantedBy = [ "multi-user.target" ];
    after = [ "atticd.service" ];
    requires = [ "atticd.service" ];
    path = with pkgs; [
      coreutils
      findutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = atticBootstrap;
      StateDirectory = "attic-bootstrap";
    };
  };
}
