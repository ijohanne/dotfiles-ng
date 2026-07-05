{ config, pkgs, ... }:

let
  garageS3Host = "s3.unixpimps.net";
  garageZone = "est1";
  garageCapacity = "1T";
  garage = "${config.services.garage.package}/bin/garage";

  garageBootstrap = pkgs.writeShellScript "garage-bootstrap" ''
    set -euo pipefail

    wait_for_garage() {
      last_error="$(mktemp)"

      for _ in $(seq 1 120); do
        if ${garage} status >/dev/null 2>"$last_error"; then
          rm -f "$last_error"
          return 0
        fi

        sleep 1
      done

      cat "$last_error" >&2
      rm -f "$last_error"
      echo "garage RPC did not become available in time" >&2
      exit 1
    }

    wait_for_garage

    node_id="$(${garage} node id | cut -d@ -f1)"

    if [ -z "$node_id" ]; then
      echo "garage node id did not become available in time" >&2
      exit 1
    fi

    if ${garage} status | grep -q 'NO ROLE ASSIGNED'; then
      ${garage} layout assign -z ${garageZone} -c ${garageCapacity} "$node_id"

      current_version="$(${garage} layout show | sed -n 's/^Current cluster layout version: \([0-9][0-9]*\)$/\1/p')"
      if [ -n "$current_version" ]; then
        next_version=$((current_version + 1))
      else
        next_version=1
      fi

      ${garage} layout apply --version "$next_version"
    fi

    if ! ${garage} key info "$(cat ${config.sops.secrets.garage_attic_key_id.path})" >/dev/null 2>&1; then
      ${garage} key import \
        "$(cat ${config.sops.secrets.garage_attic_key_id.path})" \
        "$(cat ${config.sops.secrets.garage_attic_secret_key.path})" \
        -n attic \
        --yes
    fi

    if ! ${garage} bucket info attic >/dev/null 2>&1; then
      ${garage} bucket create attic
    fi

    ${garage} bucket allow \
      --read \
      --write \
      --owner \
      attic \
      --key "$(cat ${config.sops.secrets.garage_attic_key_id.path})"
  '';
in
{
  users.groups.garage = { };

  users.users.garage = {
    isSystemUser = true;
    group = "garage";
    description = "Garage object storage service";
  };

  sops.secrets.garage_rpc_secret = {
    mode = "0400";
    owner = "garage";
    group = "garage";
  };

  sops.secrets.garage_admin_token = {
    mode = "0400";
    owner = "garage";
    group = "garage";
  };

  sops.secrets.garage_metrics_token = {
    mode = "0400";
    owner = "garage";
    group = "garage";
  };

  sops.secrets.garage_attic_key_id = { };
  sops.secrets.garage_attic_secret_key = { };

  services.garage = {
    enable = true;
    package = pkgs.garage;
    logLevel = "info";

    settings = {
      replication_factor = 1;
      db_engine = "sqlite";

      rpc_bind_addr = "127.0.0.1:3901";
      rpc_public_addr = "127.0.0.1:3901";
      rpc_secret_file = config.sops.secrets.garage_rpc_secret.path;

      allow_world_readable_secrets = false;

      s3_api = {
        api_bind_addr = "127.0.0.1:3900";
        s3_region = "garage";
      };

      admin = {
        api_bind_addr = "127.0.0.1:3903";
        admin_token_file = config.sops.secrets.garage_admin_token.path;
        metrics_token_file = config.sops.secrets.garage_metrics_token.path;
      };
    };
  };

  systemd.services.garage.serviceConfig = {
    DynamicUser = false;
    User = "garage";
    Group = "garage";
  };

  services.nginx.virtualHosts.${garageS3Host} = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3900";
      extraConfig = ''
        client_max_body_size 0;
        proxy_request_buffering off;
        proxy_buffering off;
      '';
    };
  };

  systemd.services.garage-bootstrap = {
    description = "Bootstrap Garage layout and Attic bucket";
    wantedBy = [ "multi-user.target" ];
    after = [ "garage.service" ];
    requires = [ "garage.service" ];
    path = with pkgs; [
      coreutils
      gnugrep
      gnused
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = garageBootstrap;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
