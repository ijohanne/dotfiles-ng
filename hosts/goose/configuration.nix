{ inputs, config, pkgs, lib, user, modules, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };

  interfaces = {
    external = "br-wan";
    internal = "uplink";
    uplinks = [ "enp5s0f0np0" "enp5s0f1np1" ];
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
    modules.public.nixos.services.smsGatewayClient
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
  };

  time.timeZone = "Europe/Madrid";

  services.smsGatewayClient = {
    enable = true;
    envFile = config.sops.templates."sms-env".path;
  };

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
  ];

  system.stateVersion = "22.05";
}
