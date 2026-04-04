{ inputs, config, pkgs, lib, user, modules, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };

  interfaces = {
    external = "br-wan";
    internal = "uplink";
    uplinks = [ "enp5s0f0np0" "enp5s0f1np1" ];
  };

  sms = pkgs.writeShellApplication {
    name = "sms";
    runtimeInputs = with pkgs; [ bash curl jq ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      if [[ $# -ne 1 ]]; then
        echo "Need text message as argument"
        exit 1
      fi

      source /run/secrets/rendered/sms-env

      message="$1"

      sid=$(curl -sf "http://$SMS_IP/ubus" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"call\",\"params\":[\"00000000000000000000000000000000\",\"session\",\"login\",{\"username\":\"$SMS_USER\",\"password\":\"$SMS_PASSWORD\"}]}" \
        | jq -re '.result[1].ubus_rpc_session')

      IFS=',' read -ra numbers <<< "$SMS_TARGET_NUMBER"
      for number in "''${numbers[@]}"; do
        curl -sf "http://$SMS_IP/api/messages/actions/send" -X POST \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $sid" \
          -d "{\"data\":{\"modem\":\"$SMS_MODEM\",\"number\":\"$number\",\"message\":\"$message\"}}"
        echo ""
      done
    '';
  };

  test_main_wan_uplink = pkgs.writeShellApplication {
    name = "test_main_wan_uplink";
    runtimeInputs = with pkgs; [ bash fping iproute2 systemd sms ];
    text = ''
      STATE_FILE="/var/run/wan-failover-state"
      MAIN_WAN=ppp0
      BACKUP_WAN=mobile
      PROBE_TARGETS="8.8.8.8 8.8.4.4 1.1.1.1"
      FPING_ARGS=(-c 3 -q -x 2)
      FAILBACK_THRESHOLD=3

      current_state() {
        cat "$STATE_FILE" 2>/dev/null || echo "primary"
      }

      failover_to_backup() {
        mobile_gw=$(ip route show dev mobile | awk '/default/{print $3}')
        ip route replace default via "$mobile_gw" dev mobile metric 0
        ip route replace default dev ppp0 scope link metric 9999
        echo "backup" > "$STATE_FILE"
        echo "0" > "''${STATE_FILE}.failback-count"
        sms "WAN failover: ppp0 unreachable, switched to mobile"
        systemctl restart hickory-dns.service
      }

      failback_to_primary() {
        mobile_gw=$(ip route show dev mobile | awk '/default/{print $3}')
        ip route replace default dev ppp0 scope link metric 0
        ip route replace default via "$mobile_gw" dev mobile metric 1063
        echo "primary" > "$STATE_FILE"
        rm -f "''${STATE_FILE}.failback-count"
        sms "WAN failback: ppp0 restored"
        systemctl restart hickory-dns.service
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
  _module.args = {
    inherit interfaces network;
  };

  imports = [
    modules.public.nixos.aspects.serverBase
    (import modules.private.nixos.aspects.managedRemoteHost {
      host = "goose";
      sopsFile = ../../secrets/goose.yaml;
    })
    modules.private.nixos.aspects.gooseServices
    ./hardware-configuration.nix
    ./networking.nix
  ];

  networking = {
    hostName = "goose";
    useDHCP = false;
    extraHosts = ''
      ${network.hosts.pakhet.ip} vardrun.unixpimps.net
    '';
  };

  time.timeZone = "Europe/Madrid";

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ping6" ''exec ping -6 "$@"'')
    efibootmgr
    ethtool
    ppp
    tcpdump
    conntrack-tools
    lm_sensors
    dnstop
    ipmitool
    fping
    sms
    test_main_wan_uplink
  ];

  nix.gc.options = lib.mkForce "--delete-older-than 30d";

  systemd.services.wan-failover = {
    description = "WAN failover check";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${test_main_wan_uplink}/bin/test_main_wan_uplink";
    };
  };

  systemd.timers.wan-failover = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  system.stateVersion = "22.05";
}
