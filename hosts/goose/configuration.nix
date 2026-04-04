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
    (import modules.public.nixos.services.wanFailover {
      mainInterface = "ppp0";
      backupInterface = "mobile";
      onFailoverCommand = ''sms "WAN failover: ppp0 unreachable, switched to mobile"'';
      onFailbackCommand = ''sms "WAN failback: ppp0 restored"'';
      restartServices = [ "hickory-dns.service" ];
    })
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
  ];

  nix.gc.options = lib.mkForce "--delete-older-than 30d";

  system.stateVersion = "22.05";
}
