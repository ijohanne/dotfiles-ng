{ config, lib, network, modules, users, ... }:
let
  domain = "auth.${network.domain}";
  resource = "https://prometheus.${network.domain}";
  auth = config.services.authelia.instances.observability;
  secret = name: config.sops.secrets.${name}.path;
  placeholder = name: config.sops.placeholder.${name};
  userConfig = lib.filterAttrs (_: value: value.observability or false) users;
  secretNames = [
    "observability_session_secret"
    "observability_storage_key"
    "observability_jwt_secret"
    "observability_oidc_hmac_secret"
    "observability_oidc_private_key"
    "observability_chatgpt_client_hash"
    "observability_mcp_client_hash"
  ] ++ map (name: "observability_${name}_password_hash") (builtins.attrNames userConfig);
  clientBase = {
    audience = [ resource ];
    requested_audience_mode = "implicit";
    scopes = [ "openid" "profile" "email" "offline_access" "prometheus.read" ];
    grant_types = [ "authorization_code" "refresh_token" ];
    response_types = [ "code" ];
    require_pkce = true;
    pkce_challenge_method = "S256";
    consent_mode = "explicit";
    authorization_policy = "observability";
  };
in
{
  imports = [ modules.public.nixos.services.declarativeCloudflareDns ];
  services.declarativeCloudflareDns = {
    enable = true;
    zoneId = "8cc1cba12fc23cd81482054cd2745179";
    environmentFile = config.sops.secrets.cloudflare_api_key.path;
    records = map
      (name: {
        inherit name;
        type = "CNAME";
        content = "r0.${network.domain}";
      }) [ "prometheus.${network.domain}" domain ];
  };
  sops.secrets = lib.genAttrs secretNames (_: {
    owner = auth.user;
    group = auth.group;
    restartUnits = [ "authelia-observability.service" ];
  });
  sops.templates."observability-users.yml" = {
    owner = auth.user;
    group = auth.group;
    restartUnits = [ "authelia-observability.service" ];
    content = builtins.toJSON {
      users = lib.mapAttrs
        (name: user: {
          displayname = user.name;
          inherit (user) email;
          password = placeholder "observability_${name}_password_hash";
          groups = [ "observability" ];
        })
        userConfig;
    };
  };
  sops.templates."observability-clients.yml" = {
    owner = auth.user;
    group = auth.group;
    restartUnits = [ "authelia-observability.service" ];
    content = builtins.toJSON {
      identity_providers.oidc.clients = [
        (clientBase // {
          client_id = "chatgpt-prometheus";
          client_name = "ChatGPT Prometheus";
          client_secret = placeholder "observability_chatgpt_client_hash";
          token_endpoint_auth_method = "client_secret_post";
          redirect_uris = [ "https://chatgpt.com/connector_platform_oauth_redirect" ];
        })
        (clientBase // {
          client_id = "prometheus-cli";
          client_name = "Prometheus CLI";
          public = true;
          token_endpoint_auth_method = "none";
          redirect_uris = [ "http://127.0.0.1:18443/callback" ];
        })
        {
          client_id = "prometheus-mcp";
          client_name = "Prometheus MCP token verification";
          client_secret = placeholder "observability_mcp_client_hash";
          token_endpoint_auth_method = "client_secret_basic";
          introspection_endpoint_auth_method = "client_secret_basic";
          grant_types = [ "client_credentials" ];
          response_types = [ "code" ];
          scopes = [ "prometheus.read" ];
          audience = [ resource ];
        }
      ];
    };
  };
  services.authelia.instances.observability = {
    enable = true;
    secrets = {
      jwtSecretFile = secret "observability_jwt_secret";
      storageEncryptionKeyFile = secret "observability_storage_key";
      sessionSecretFile = secret "observability_session_secret";
      oidcHmacSecretFile = secret "observability_oidc_hmac_secret";
      oidcIssuerPrivateKeyFile = secret "observability_oidc_private_key";
    };
    settingsFiles = [ config.sops.templates."observability-clients.yml".path ];
    settings = {
      theme = "dark";
      log.level = "info";
      server.address = "tcp://127.0.0.1:9091/";
      authentication_backend = {
        password_reset.disable = true;
        file.path = config.sops.templates."observability-users.yml".path;
      };
      access_control.default_policy = "deny";
      session.cookies = [{
        domain = network.domain;
        authelia_url = "https://${domain}";
        default_redirection_url = resource;
      }];
      storage.local.path = "/var/lib/authelia-observability/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-observability/notifications.txt";
      identity_providers.oidc = {
        enforce_pkce = "always";
        lifespans.access_token = "15m";
        lifespans.refresh_token = "30d";
        scopes."prometheus.read".claims = [ ];
        authorization_policies.observability = {
          default_policy = "deny";
          rules = [{ policy = "one_factor"; subject = "group:observability"; }];
        };
      };
    };
  };
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      extraConfig = ''
        proxy_set_header X-Forwarded-Proto https;
      '';
    };
  };
  services.nginx.appendHttpConfig = ''
    limit_req_zone $binary_remote_addr zone=prometheus_mcp:10m rate=5r/s;
  '';
  services.nginx.virtualHosts."prometheus.${network.domain}" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."= /mcp" = {
      proxyPass = "http://${network.hosts.goose.ips.mgnt}:9002/mcp";
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 90s;
        proxy_set_header X-Forwarded-Proto https;
        client_max_body_size 1m;
        limit_req zone=prometheus_mcp burst=20 nodelay;
        limit_req_status 429;
      '';
    };
    locations."= /.well-known/oauth-protected-resource".proxyPass = "http://${network.hosts.goose.ips.mgnt}:9002";
    locations."= /.well-known/oauth-protected-resource/mcp".proxyPass = "http://${network.hosts.goose.ips.mgnt}:9002";
    locations."= /".return = "200 'Prometheus MCP endpoint: /mcp'";
    locations."/".return = "404";
  };
}
