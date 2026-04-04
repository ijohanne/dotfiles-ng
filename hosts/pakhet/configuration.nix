{ inputs, config, pkgs, lib, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };
in
{
  _module.args = {
    inherit network;
  };

  imports = [
    ../../modules/community/nixos/aspects/server-base.nix
    (import ../../configs/managed-remote-host.nix {
      host = "pakhet";
      sopsFile = ../../secrets/pakhet.yaml;
    })
    ./hardware-configuration.nix
    ./services
  ];

  networking = {
    hostName = "pakhet";
    useDHCP = true;
    nameservers = [ "${network.hosts.goose.ips.wired}" ];
  };

  networking.firewall.extraCommands = ''
    ip6tables -I INPUT -i enp0s5 -p icmpv6 --icmpv6-type router-advertisement \
      -m mac --mac-source b8:27:eb:ff:f8:5f \
      -j DROP
  '';

  # kresd is pulled in by nixos-mailserver for DANE — keep it for postfix
  # but don't let it hijack resolv.conf; system DNS goes to goose
  networking.resolvconf.useLocalResolver = lib.mkForce false;

  time.timeZone = "Europe/Madrid";

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ping6" ''exec ping -6 "$@"'')
  ];

  system.stateVersion = "22.05";
}
