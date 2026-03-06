{ inputs, config, pkgs, lib, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };

  interfaces = {
    external = "wan";
    internal = "uplink";
    uplinks = [ "enp5s0f0np0" "enp5s0f1np1" ];
  };

  sms = pkgs.writeShellApplication {
    name = "sms";
    runtimeInputs = with pkgs; [ bash curl ];
    text = ''
      #!/usr/bin/env bash

      if [[ $# -ne 1 ]];
      then
        echo "Need text message as argument"
        exit 1
      fi

      source /run/secrets-rendered/sms-env

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

  test_connection = pkgs.writeShellApplication {
    name = "test_connection";
    runtimeInputs = with pkgs; [ bash fping ];
    text = ''
      #!/usr/bin/env bash

      if [[ $(id -u) -ne 0 ]];
      then
        echo "This script needs to run as root to be able to modify routing table"
        exit 1
      fi

      MAIN_WAN=ppp0
      BACKUP_WAN=mobile

      args=(-c 4 -q -x 2)

      if fping -I "$MAIN_WAN" "''${args[@]}" 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 208.67.222.222 208.67.220.220 > /dev/null 2>&1;
      then
        echo "Main line is up. Doing nothing"
        exit 0
      else
        echo "Main line appears to be down. Testing backup line."
        if fping -I "$BACKUP_WAN" "''${args[@]}" 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 208.67.222.222 208.67.220.220 > /dev/null 2>&1;
        then
          echo "Backup line is up. Changing to backup"
          exit 0
        else
          echo "Backup line is also down. Can't do anything"
          exit 0
        fi
      fi
    '';
  };
in
{
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    (import ./networking.nix { inherit interfaces; })
    (import ./services { inherit interfaces network; })
  ];

  system.stateVersion = "22.05";

  networking = {
    hostName = "goose";
    useDHCP = false;
  };

  time.timeZone = "Europe/Madrid";

  environment.systemPackages = with pkgs; [
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
    test_connection
    (writeShellScriptBin "deploy-goose" ''
      exec sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#goose --refresh
    '')
  ];

  nix.gc.options = lib.mkForce "--delete-older-than 30d";

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
