{ config, pkgs, lib, user, ... }:

let
  homeDir = if pkgs.stdenv.isDarwin then "/Users/${user.username}" else "/home/${user.username}";
  hostname = config.networking.hostName;
  
  secretsFile = {
    "macbook" = ../secrets/macbook.yaml;
    "ij-desktop" = ../secrets/macbook.yaml;
  }.${hostname} or ../secrets/macbook.yaml;
in
{
  sops = {
    defaultSopsFile = secretsFile;

    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "${homeDir}/.config/sops/age/keys.txt";
      generateKey = false;
    };

    secrets = lib.mkMerge [
      (lib.mkIf (hostname == "macbook") {
        cloudflare_unixpimps_net_api_key = {};
        nix_remote_builder_ssh_key = {
          mode = "0600";
        };
      })
    ];
  };

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}
