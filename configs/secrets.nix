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
  };

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}
