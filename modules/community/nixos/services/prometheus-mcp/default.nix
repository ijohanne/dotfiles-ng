{ config, lib, pkgs, ... }:
let
  cfg = config.services.prometheusMcp;
in
{
  options.services.prometheusMcp = {
    enable = lib.mkEnableOption "authenticated Prometheus MCP";
    package = lib.mkOption { type = lib.types.package; };
    listenAddress = lib.mkOption { type = lib.types.str; default = "127.0.0.1:9002"; };
    prometheusUrl = lib.mkOption { type = lib.types.str; default = "http://127.0.0.1:9001"; };
    resource = lib.mkOption { type = lib.types.str; };
    issuer = lib.mkOption { type = lib.types.str; };
    introspectionUrl = lib.mkOption { type = lib.types.str; };
    clientId = lib.mkOption { type = lib.types.str; default = "prometheus-mcp"; };
    clientSecretFile = lib.mkOption { type = lib.types.str; };
    accessTokenPrefix = lib.mkOption { type = lib.types.str; default = ""; };
    skillsDirectory = lib.mkOption { type = lib.types.path; };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.prometheus-mcp = {
      description = "Read-only Prometheus MCP with OAuth and Agent Skills";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "prometheus.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = lib.escapeShellArgs ([
          "${cfg.package}/bin/prometheus-mcp"
          "--mcp.transport=http"
          "--web.listen-address=${cfg.listenAddress}"
          "--prometheus.url=${cfg.prometheusUrl}"
          "--prometheus.timeout=20s"
          "--prometheus.truncation-limit=100"
          "--prometheus.enforce-truncation-limit"
          "--mcp.enable-toon-output"
          "--runbooks.directory=${cfg.skillsDirectory}"
          "--oauth.issuer=${cfg.issuer}"
          "--oauth.resource=${cfg.resource}"
          "--oauth.introspection-url=${cfg.introspectionUrl}"
          "--oauth.client-id=${cfg.clientId}"
          "--oauth.access-token-prefix=${cfg.accessTokenPrefix}"
          "--oauth.client-secret-file=%d/oauth-client-secret"
        ] ++ map (tool: "--mcp.tools=${tool}") [ "list_targets" "list_alerts" "list_rules" "healthy" "ready" "build_info" ]);
        LoadCredential = "oauth-client-secret:${cfg.clientSecretFile}";
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        UMask = "0077";
      };
    };
  };
}
