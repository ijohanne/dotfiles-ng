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
    ./mercy.nix
    ./grpc-proxier.nix
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

  # Screeny k111-agw secrets (renamed from screeny_*)
  # NOTE: Rename keys in secrets/pakhet.yaml:
  #   screeny_jwt_secret -> screeny_k111_agw_jwt_secret
  #   screeny_admin_password -> screeny_k111_agw_admin_password
  #   screeny_telegram_bot_token -> screeny_k111_agw_telegram_bot_token
  sops.secrets.screeny_k111_agw_jwt_secret = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  sops.secrets.screeny_k111_agw_admin_password = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  sops.secrets.screeny_k111_agw_telegram_bot_token = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  # Screeny k111-test secrets
  sops.secrets.screeny_k111_test_jwt_secret = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  sops.secrets.screeny_k111_test_admin_password = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  # Screeny k131-god secrets
  sops.secrets.screeny_k131_god_jwt_secret = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  sops.secrets.screeny_k131_god_admin_password = {
    mode = "0400";
    owner = "screeny";
    group = "screeny";
  };

  # gRPC proxier secrets
  sops.secrets.grpc_proxier_cctax_admin_password = {
    mode = "0400";
    owner = "grpc-proxier";
    group = "grpc-proxier";
  };

  # Mercy secrets
  sops.secrets.mercy_auth_token = {
    mode = "0400";
    owner = "mercy";
    group = "mercy";
  };

  sops.secrets.mercy_tb_email = {
    mode = "0400";
    owner = "mercy";
    group = "mercy";
  };

  sops.secrets.mercy_tb_password = {
    mode = "0400";
    owner = "mercy";
    group = "mercy";
  };

  sops.secrets.mercy_admin_name = {
    mode = "0400";
    owner = "mercy";
    group = "mercy";
  };

  sops.secrets.mercy_admin_password = {
    mode = "0400";
    owner = "mercy";
    group = "mercy";
  };
}
