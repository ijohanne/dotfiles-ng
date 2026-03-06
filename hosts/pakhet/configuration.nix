{ inputs, config, pkgs, lib, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };
in
{
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    (import ./services { inherit network; })
  ];

  system.stateVersion = "22.05";

  networking = {
    hostName = "pakhet";
    useDHCP = true;
  };

  time.timeZone = "Europe/Madrid";

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_builder_access_tokens.path}
  '';

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "deploy-pakhet" ''
      exec sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#pakhet --refresh
    '')
  ];

  sops = {
    defaultSopsFile = ../../secrets/pakhet.yaml;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
}
