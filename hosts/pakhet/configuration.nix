{ inputs, config, pkgs, lib, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };
in
{
  _module.args = {
    inherit network;
  };

  imports = [
    ../../configs/server.nix
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
    interfaces.enp0s5.ipv6.addresses = [
      {
        address = network.hosts.pakhet.ip6;
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = network.hosts.goose.ip6s.wired;
      interface = "enp0s5";
    };
  };

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.default.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.enp0s5.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.all.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.default.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.enp0s5.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.all.use_tempaddr" = lib.mkForce 0;
    "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 0;
    "net.ipv6.conf.enp0s5.use_tempaddr" = lib.mkForce 0;
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
