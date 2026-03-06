{ inputs, config, pkgs, lib, user, ... }:

{
  imports = [
    ../../configs/server.nix
    ./services
  ];

  system.stateVersion = "25.11";

  networking = {
    hostName = "khonsu";
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
  };

  time.timeZone = "Europe/Madrid";

  # GRUB device is set automatically by disko via the EF02 partition

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "deploy-khonsu" ''
      exec sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#khonsu --refresh
    '')
  ];

  sops = {
    defaultSopsFile = ../../secrets/khonsu.yaml;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
}
