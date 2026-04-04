{ inputs, config, pkgs, lib, user, modules, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };
in
{
  _module.args = {
    inherit network;
  };

  imports = [
    modules.public.nixos.aspects.serverBase
    (import modules.private.nixos.aspects.managedRemoteHost {
      host = "pakhet";
      sopsFile = ../../secrets/pakhet.yaml;
    })
    modules.private.nixos.aspects.pakhetServices
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "pakhet";
    useDHCP = true;
    nameservers = [ "${network.hosts.goose.ips.wired}" ];
  };

  # kresd is pulled in by nixos-mailserver for DANE — keep it for postfix
  # but don't let it hijack resolv.conf; system DNS goes to goose
  networking.resolvconf.useLocalResolver = lib.mkForce false;

  time.timeZone = "Europe/Madrid";

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ping6" ''exec ping -6 "$@"'')
  ];

  system.stateVersion = "22.05";
}
