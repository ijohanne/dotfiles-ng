{ config, pkgs, lib, inputs, self, users, user, modules, ... }:

let
  network = modules.private.inventory.network { inherit lib; };
in
{
  _module.args = {
    inherit network;
  };

  imports = [
    modules.public.nixos.aspects.serverBase
    (import modules.private.nixos.aspects.managedRemoteHost {
      host = "seshat";
      sopsFile = ../../secrets/seshat.yaml;
    })
    modules.private.nixos.aspects.seshatServices
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "seshat";
    useDHCP = false;

    interfaces.eno1 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "51.75.118.69";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "2001:41d0:303:8545::1";
        prefixLength = 128;
      }];
      ipv6.routes = [{
        address = "2001:41d0:303:85ff:ff:ff:ff:ff";
        prefixLength = 128;
      }];
    };

    defaultGateway = {
      address = "51.75.118.254";
      interface = "eno1";
    };
    defaultGateway6 = {
      address = "2001:41d0:303:85ff:ff:ff:ff:ff";
      interface = "eno1";
    };

    nameservers = [ "213.186.33.99" "1.1.1.1" "2606:4700:4700::1111" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 51820 ];
      interfaces.wg0.allowedTCPPorts = [ 8090 ];
    };
  };

  time.timeZone = "Europe/Paris";

  # GRUB device is set automatically by disko via the EF02 partition.

  system.stateVersion = "25.11";
}
