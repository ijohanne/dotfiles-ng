{ config, pkgs, lib, ... }:

{
  imports = [
    ./nginx.nix
    ./mariadb.nix
    ./postgresql.nix
    ./gitea.nix
    ./geoip-updater.nix
    ./pastebin.nix
    ./backup.nix
    ./estepona.nix
    ./kubernetes.nix
    ./screeny.nix
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

  # TODO: Add secret screeny_jwt_secret to secrets/pakhet.yaml
  sops.secrets.screeny_jwt_secret = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  # TODO: Add secret screeny_admin_password to secrets/pakhet.yaml
  sops.secrets.screeny_admin_password = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  # Telegram bot token for Screeny
  sops.secrets.screeny_telegram_bot_token = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };
}
