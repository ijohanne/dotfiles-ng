{ config, lib, pkgs, ... }:
let
  cfg = config.services.declarativeCloudflareDns;
  settings = pkgs.writeText "cloudflare-dns.json" (builtins.toJSON {
    inherit (cfg) zoneId records;
  });
in
{
  options.services.declarativeCloudflareDns = {
    enable = lib.mkEnableOption "declarative Cloudflare DNS records";
    zoneId = lib.mkOption { type = lib.types.str; };
    environmentFile = lib.mkOption { type = lib.types.str; };
    records = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          type = lib.mkOption { type = lib.types.enum [ "A" "AAAA" "CNAME" ]; };
          content = lib.mkOption { type = lib.types.str; };
          ttl = lib.mkOption { type = lib.types.ints.positive; default = 300; };
          proxied = lib.mkOption { type = lib.types.bool; default = false; };
        };
      });
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.cloudflare-dns = {
      description = "Reconcile declared Cloudflare DNS records";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        EnvironmentFile = cfg.environmentFile;
        ExecStart = "${pkgs.python3}/bin/python3 ${./sync.py} ${settings}";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      };
    };
    systemd.timers.cloudflare-dns = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1h";
        RandomizedDelaySec = "1min";
      };
    };
  };
}
