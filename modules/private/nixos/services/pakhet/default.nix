{ network, config, pkgs, lib, ... }:

let
  screenySecret = {
    mode = "0440";
    owner = config.services.screeny.user;
    group = config.services.screeny.group;
  };
in
{
  imports = [
    ./nginx.nix
    ./garage.nix
    ./attic.nix
    ./mariadb.nix
    ./postgresql.nix
    ./gitea.nix
    ./geoip-updater.nix
    ./pastebin.nix
    ./backup.nix
    ./keycloak.nix
    ./estepona.nix
    ./kubernetes.nix
    ./screeny.nix
    ./grpc-proxier.nix
    ./pdf-detective.nix
    ./shouldidrinktoday.nix
    ./unixpimpsnet.nix
    ./mailserver.nix
    ./mail-autoconfig.nix
    ./plausible.nix
    ./perlpimpnet.nix
    ./hrafnsyn.nix
    ./vardrun.nix
    ./node-exporter.nix
    ./pg-exporter.nix
    ./zot.nix
  ];

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

  sops.secrets.screeny_k111_agw_jwt_secret = screenySecret;
  sops.secrets.screeny_k111_agw_admin_password = screenySecret;
  sops.secrets.screeny_k111_agw_telegram_bot_token = screenySecret;
  sops.secrets.screeny_k111_agw_chest_counter_api_key = screenySecret;
  sops.secrets.screeny_control_user_ij_pass = screenySecret;

  # gRPC proxier secrets
  sops.secrets.grpc_proxier_cctax_admin_password = {
    mode = "0400";
    owner = "grpc-proxier";
    group = "grpc-proxier";
  };

  # Vardrun unixpimps secrets
  sops.secrets.vardrun_unixpimps_jwt_secret = {
    mode = "0400";
    owner = "vardrun_unixpimps";
    group = "vardrun_unixpimps";
  };

  sops.secrets.vardrun_unixpimps_pat_encryption_key = {
    mode = "0400";
    owner = "vardrun_unixpimps";
    group = "vardrun_unixpimps";
  };

  sops.secrets.vardrun_unixpimps_secret_key_base = {
    mode = "0400";
    owner = "vardrun_unixpimps";
    group = "vardrun_unixpimps";
  };

  sops.secrets.vardrun_unixpimps_global_pat = {
    mode = "0400";
    owner = "vardrun_unixpimps";
    group = "vardrun_unixpimps";
  };

  sops.secrets.vardrun_unixpimps_ij_password = {
    mode = "0400";
    owner = "vardrun_unixpimps";
    group = "vardrun_unixpimps";
  };

  # Vardrun opsplaza secrets
  sops.secrets.vardrun_opsplaza_jwt_secret = {
    mode = "0400";
    owner = "vardrun_opsplaza";
    group = "vardrun_opsplaza";
  };

  sops.secrets.vardrun_opsplaza_pat_encryption_key = {
    mode = "0400";
    owner = "vardrun_opsplaza";
    group = "vardrun_opsplaza";
  };

  sops.secrets.vardrun_opsplaza_secret_key_base = {
    mode = "0400";
    owner = "vardrun_opsplaza";
    group = "vardrun_opsplaza";
  };

  sops.secrets.vardrun_opsplaza_global_pat = {
    mode = "0400";
    owner = "vardrun_opsplaza";
    group = "vardrun_opsplaza";
  };

  sops.secrets.vardrun_opsplaza_ij_password = {
    mode = "0400";
    owner = "vardrun_opsplaza";
    group = "vardrun_opsplaza";
  };

  # Plausible secrets
  sops.secrets.plausible_secret_key_base = { };
  sops.secrets.mail_password_no_reply = { };

  # Mail server secrets (hashed passwords)
  sops.secrets.mail_hashed_password_ij.restartUnits = [ "dovecot.service" ];
  sops.secrets.mail_hashed_password_brother_hallway.restartUnits = [ "dovecot.service" ];
  sops.secrets.mail_hashed_password_mj.restartUnits = [ "dovecot.service" ];
  sops.secrets.mail_hashed_password_no_reply.restartUnits = [ "dovecot.service" ];
  sops.secrets.mail_hashed_password_themailer.restartUnits = [ "dovecot.service" ];
  sops.secrets.mail_hashed_password_alertmanager.restartUnits = [ "dovecot.service" ];
}
