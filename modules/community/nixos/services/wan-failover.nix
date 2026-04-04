{
  name ? "wan-failover",
  description ? "WAN failover check",
  mainInterface,
  backupInterface,
  probeTargets ? [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ],
  fpingArgs ? [ "-c" "3" "-q" "-x" "2" ],
  failbackThreshold ? 3,
  stateFile ? "/var/run/${name}-state",
  failoverPrimaryMetric ? 9999,
  failoverBackupMetric ? 0,
  failbackPrimaryMetric ? 0,
  failbackBackupMetric ? 1063,
  onFailoverCommand ? null,
  onFailbackCommand ? null,
  restartServices ? [ ],
  onBootSec ? "2min",
  onUnitActiveSec ? "1min",
  exposeCommand ? true
}:

{ pkgs, lib, ... }:

let
  shellQuote = lib.escapeShellArg;
  probeTargetsStr = builtins.concatStringsSep " " probeTargets;
  fpingArgsStr = builtins.concatStringsSep " " fpingArgs;
  restartSnippet = lib.concatMapStringsSep "\n" (service: ''
    systemctl restart ${shellQuote service}
  '') restartServices;
  failoverSnippet = lib.optionalString (onFailoverCommand != null) ''
    ${onFailoverCommand}
  '';
  failbackSnippet = lib.optionalString (onFailbackCommand != null) ''
    ${onFailbackCommand}
  '';

  command = pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = with pkgs; [ bash fping iproute2 systemd gawk coreutils ];
    text = ''
      STATE_FILE=${shellQuote stateFile}
      MAIN_WAN=${shellQuote mainInterface}
      BACKUP_WAN=${shellQuote backupInterface}
      PROBE_TARGETS=${shellQuote probeTargetsStr}
      FPING_ARGS=(${fpingArgsStr})
      FAILBACK_THRESHOLD=${toString failbackThreshold}

      current_state() {
        cat "$STATE_FILE" 2>/dev/null || echo "primary"
      }

      backup_gateway() {
        ip route show dev "$BACKUP_WAN" | awk '/default/{print $3; exit}'
      }

      failover_to_backup() {
        backup_gw=$(backup_gateway)
        ip route replace default via "$backup_gw" dev "$BACKUP_WAN" metric ${toString failoverBackupMetric}
        ip route replace default dev "$MAIN_WAN" scope link metric ${toString failoverPrimaryMetric}
        echo "backup" > "$STATE_FILE"
        echo "0" > "''${STATE_FILE}.failback-count"
        ${failoverSnippet}
        ${restartSnippet}
      }

      failback_to_primary() {
        backup_gw=$(backup_gateway)
        ip route replace default dev "$MAIN_WAN" scope link metric ${toString failbackPrimaryMetric}
        ip route replace default via "$backup_gw" dev "$BACKUP_WAN" metric ${toString failbackBackupMetric}
        echo "primary" > "$STATE_FILE"
        rm -f "''${STATE_FILE}.failback-count"
        ${failbackSnippet}
        ${restartSnippet}
      }

      if [[ "$(current_state)" == "primary" ]]; then
        # shellcheck disable=SC2086
        if ! fping -I "$MAIN_WAN" "''${FPING_ARGS[@]}" $PROBE_TARGETS >/dev/null 2>&1; then
          # shellcheck disable=SC2086
          if fping -I "$BACKUP_WAN" "''${FPING_ARGS[@]}" $PROBE_TARGETS >/dev/null 2>&1; then
            failover_to_backup
          fi
        fi
      else
        # shellcheck disable=SC2086
        if fping -I "$MAIN_WAN" "''${FPING_ARGS[@]}" $PROBE_TARGETS >/dev/null 2>&1; then
          count=$(cat "''${STATE_FILE}.failback-count" 2>/dev/null || echo 0)
          count=$((count + 1))
          if [[ $count -ge $FAILBACK_THRESHOLD ]]; then
            failback_to_primary
          else
            echo "$count" > "''${STATE_FILE}.failback-count"
          fi
        else
          echo "0" > "''${STATE_FILE}.failback-count"
        fi
      fi
    '';
  };
in
{
  environment.systemPackages = lib.optionals exposeCommand [ command ];

  systemd.services.${name} = {
    inherit description;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${command}/bin/${name}";
    };
  };

  systemd.timers.${name} = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = onBootSec;
      OnUnitActiveSec = onUnitActiveSec;
    };
  };
}
