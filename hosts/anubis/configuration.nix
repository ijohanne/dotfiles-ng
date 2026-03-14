{ config, pkgs, lib, inputs, self, users, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };
  deploy = import ../../configs/deploy { inherit pkgs; };
in
{
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    ./wireguard-protonvpn.nix
    (import ./wireguard-backhaul.nix { inherit network; })
    ./qbittorrent.nix
    (import ./nginx-torrent.nix { inherit network; })
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

  sops = {
    defaultSopsFile = ../../secrets/anubis.yaml;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    secrets = {
      "protonvpn/private_key" = { };
      "backhaul/private_key" = { };
      "qbittorrent/webui_password" = { owner = "qbittorrent"; };
      "acme/cloudflare_api_key" = { owner = "acme"; };
    };
  };

  services.proton-port-sync = {
    enable = true;
    gateway = "10.2.0.1";
    qbtUser = "admin";
    qbtPasswordFile = config.sops.secrets."qbittorrent/webui_password".path;
    metrics = {
      enable = true;
      address = "10.100.0.10";
      port = 9834;
    };
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
  boot.swraid.enable = true;

  environment.systemPackages = with pkgs; [
    (deploy.mkDeployScript {
      name = "deploy-anubis";
      host = "anubis";
    })
  ];

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
