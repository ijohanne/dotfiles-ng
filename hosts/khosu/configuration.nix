{ inputs, config, pkgs, lib, user, ... }:

{
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    ./services
  ];

  system.stateVersion = "25.11";

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
    (writeShellScriptBin "deploy-khosu" ''
      if [ -d "$HOME/git/dotfiles-ng" ]; then
        exec sudo nixos-rebuild switch --flake "$HOME/git/dotfiles-ng#khosu"
      else
        exec sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#khosu --refresh
      fi
    '')
  ];

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
}
