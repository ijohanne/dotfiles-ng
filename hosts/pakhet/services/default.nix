{ network, ... }:

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./nginx.nix
    ./mariadb.nix
    ./postgresql.nix
    ./gitea.nix
    ./geoip-updater.nix
    ./pastebin.nix
    ./backup.nix
    (import ./estepona.nix { inherit network; })
    (import ./kubernetes.nix { inherit network; })
    ./screeny.nix
    ./mercy.nix
    (import ./grpc-proxier.nix { inherit network; })
    ./pdf-detective.nix
    ./shouldidrinktoday.nix
    ./unixpimpsnet.nix
    ./mailserver.nix
    ./plausible.nix
    ./perlpimpnet.nix
  ];

  sops.secrets.nix_builder_access_tokens = { };
  sops.secrets.cloudflare_api_key = { };

  sops.secrets.opsplaza_smtp_pass = { };

  sops.templates."themailer-smtp-credentials" = {
    content = "themailer@unixpimps.net:${config.sops.placeholder.opsplaza_smtp_pass}";
    mode = "0400";
    owner = "themailer-wrapper";
    group = "themailer-wrapper";
  };

  sops.secrets.themailer_wrapper_customer_id = {
    mode = "0400";
    owner = "themailer-wrapper";
    group = "themailer-wrapper";
  };

  services.themailer-wrapper = {
    enable = true;
    customerIdFile = config.sops.secrets.themailer_wrapper_customer_id.path;
    baseUrl = "https://themailer.opsplaza.com";
    smtpHost = "pakhet.est.unixpimps.net";
    smtpPort = 25;
    smtpCredentialsFile = config.sops.templates."themailer-smtp-credentials".path;
    listenPort = 12002;
    domain = "themailer.opsplaza.com";
    acme = true;
    forceSSL = false;
  };

  sops.secrets.maxmind_api_key = {
    mode = "0770";
    owner = "geoip";
    group = "srv";
  };

  sops.secrets.backup_ssh_key = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

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

  # Plausible secrets
  sops.secrets.plausible_secret_key_base = { };

  # Mail server secrets (hashed passwords)
  sops.secrets.mail_hashed_password_ij = { };
  sops.secrets.mail_hashed_password_brother_hallway = { };
  sops.secrets.mail_hashed_password_mj = { };
  sops.secrets.mail_hashed_password_no_reply = { };
  sops.secrets.mail_hashed_password_themailer = { };
  sops.secrets.mail_hashed_password_alertmanager = { };
}
