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
      host = "anubis";
      sopsFile = ../../secrets/anubis.yaml;
    })
    modules.private.nixos.aspects.anubisServices
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "anubis";
    useDHCP = false;

    interfaces.eno1 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "5.196.77.4";
        prefixLength = 24;
      }];
    };

    defaultGateway = {
      address = "5.196.77.254";
      interface = "eno1";
    };

    nameservers = [ "10.2.0.1" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 51820 51821 ];
      interfaces.wg1.allowedTCPPorts = [ 443 9834 ];
    };
  };

  sops.secrets = {
    "protonvpn/private_key" = { };
    "backhaul/private_key" = { };
    "qbittorrent/webui_password" = { owner = "qbittorrent"; };
    "acme/cloudflare_api_key" = { owner = "acme"; };
  };

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot/ESP0"; }
      { devices = [ "nodev" ]; path = "/boot/ESP1"; }
    ];
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      PROGRAM /run/current-system/sw/bin/true
    '';
  };

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
