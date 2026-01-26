{ config, pkgs, lib, ... }:

{
  imports = [
    ./nginx.nix
    ./mariadb.nix
    ./gitea.nix
    ./geoip-updater.nix
    ./pastebin.nix
    ./backup.nix
    ./estepona.nix
    ./kubernetes.nix
  ];

  # TODO: Add secret cloudflare_api_key to secrets/pakhet.yaml
  sops.secrets.cloudflare_api_key = {};

  # TODO: Add secret maxmind_api_key to secrets/pakhet.yaml
  sops.secrets.maxmind_api_key = {
    mode = "0770";
    owner = "geoip";
    group = "srv";
  };

  # TODO: Add secret backup_ssh_key to secrets/pakhet.yaml
  sops.secrets.backup_ssh_key = {
    mode = "0400";
    owner = "root";
    group = "root";
  };
}
