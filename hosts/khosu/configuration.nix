{ inputs, config, pkgs, lib, user, modules, ... }:

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
      host = "khosu";
      sopsFile = ../../secrets/khosu.yaml;
      installDeployScript = false;
    })
    modules.private.nixos.aspects.khosuServices
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "khosu";
    useDHCP = false;

    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "159.195.24.170";
        prefixLength = 22;
      }];
      ipv6.addresses = [{
        address = "2a0a:4cc0:c1:4af3::1";
        prefixLength = 64;
      }];
    };

    defaultGateway = {
      address = "159.195.24.1";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" "2606:4700:4700::1111" ];
  };

  time.timeZone = "Europe/Madrid";

  # GRUB device is set automatically by disko via the EF02 partition

  system.stateVersion = "25.11";
}
