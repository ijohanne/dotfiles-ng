{ inputs, config, pkgs, lib, user, ... }:

let
  deploy = import ../../configs/deploy { inherit pkgs; };
  network = import ../../configs/network.nix { inherit lib; };
in
{
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    (import ./services { inherit network; })
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

  environment.systemPackages = with pkgs; [
    (deploy.mkDeployScript {
      name = "deploy-khosu";
      host = "khosu";
    })
  ];

  sops.secrets.nix_builder_access_tokens = { };

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_builder_access_tokens.path}
  '';

  sops = {
    defaultSopsFile = ../../secrets/khosu.yaml;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  system.stateVersion = "25.11";
}
