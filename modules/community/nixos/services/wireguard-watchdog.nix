{ interface }:
{ network, pkgs, ... }:

let
  gateway = network.hosts.wg-goose.ip;
  script = pkgs.writeShellScript "wg-watchdog-${interface}" ''
    if ! ${pkgs.iputils}/bin/ping -c 3 -W 5 ${gateway} > /dev/null 2>&1; then
      echo "WireGuard gateway ${gateway} unreachable on ${interface}, restarting"
      systemctl restart wireguard-${interface}
    fi
  '';
in
{
  systemd.services."wireguard-watchdog-${interface}" = {
    description = "WireGuard watchdog for ${interface}";
    after = [ "wireguard-${interface}.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = script;
    };
  };

  systemd.timers."wireguard-watchdog-${interface}" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
      RandomizedDelaySec = "30s";
    };
  };
}
