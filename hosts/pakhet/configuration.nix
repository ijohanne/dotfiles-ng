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
    hosts = {
      "127.0.0.1" = [ "git.unixpimps.net" ];
    };
  };

  time.timeZone = "Europe/Madrid";

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_builder_access_tokens.path}
    netrc-file = ${config.sops.templates."nix-netrc".path}
  '';

  sops.templates."nix-netrc" = {
    content = ''
      machine git.unixpimps.net
      login ijohanne
      password ${config.sops.placeholder.gitea_access_token}
    '';
    mode = "0400";
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "deploy-pakhet" ''
      if [ -d "$HOME/git/dotfiles-ng" ]; then
        exec sudo nixos-rebuild switch --flake "$HOME/git/dotfiles-ng#pakhet"
      else
        exec sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#pakhet --refresh
      fi
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
