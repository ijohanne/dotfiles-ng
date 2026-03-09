{ inputs, config, pkgs, lib, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };

  interfaces = {
    external = "br-wan";
    internal = "uplink";
    uplinks = [ "enp5s0f0np0" "enp5s0f1np1" ];
  };

  sms = pkgs.writeShellApplication {
    name = "sms";
    runtimeInputs = with pkgs; [ bash curl ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      if [[ $# -ne 1 ]];
      then
        echo "Need text message as argument"
        exit 1
      fi

      source /run/secrets/rendered/sms-env

      message="$1"

      url="http://$SMS_IP/cgi-bin/sms_send"

      curl --get \
        --data-urlencode "username=$SMS_USER" \
        --data-urlencode "password=$SMS_PASSWORD" \
        --data-urlencode "number=$SMS_TARGET_NUMBER" \
        --data-urlencode "text=$message" \
        "$url"
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
        systemctl restart unbound.service
      }

      failback_to_primary() {
        mobile_gw=$(ip route show dev mobile | awk '/default/{print $3}')
        ip route replace default dev ppp0 scope link metric 0
        ip route replace default via "$mobile_gw" dev mobile metric 1063
        echo "primary" > "$STATE_FILE"
        rm -f "''${STATE_FILE}.failback-count"
        sms "WAN failback: ppp0 restored"
        systemctl restart unbound.service
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
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    (import ./networking.nix { inherit interfaces network; })
    (import ./services { inherit interfaces network; })
  ];

  system.stateVersion = "22.05";

  networking = {
    hostName = "goose";
    useDHCP = false;
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
    (writeShellScriptBin "deploy-goose" ''
      for dir in /home/*/git/dotfiles-ng /root/git/dotfiles-ng; do
        if [ -d "$dir/.git" ]; then
          git -C "$dir" add -A
          exec sudo nixos-rebuild switch --flake "$dir#goose"
        fi
      done
      exec sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#goose --refresh
    '')
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

  sops = {
    defaultSopsFile = ../../secrets/goose.yaml;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
}
