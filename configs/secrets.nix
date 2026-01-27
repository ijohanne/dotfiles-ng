{ config, pkgs, lib, user, ... }:

let
  homeDir = if pkgs.stdenv.isDarwin then "/Users/${user.username}" else "/home/${user.username}";
  sshHostKey = "/etc/ssh/ssh_host_ed25519_key";
in
{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;

    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "${homeDir}/.config/sops/age/keys.txt";
      generateKey = false;
    };

    secrets.cloudflare_unixpimps_net_api_key = {};
    secrets.nix_remote_builder_ssh_key = lib.mkIf pkgs.stdenv.isDarwin {
      path = "/etc/nix/builder_ed25519";
      mode = "0600";
      owner = "root";
    };
  };

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}
