{ config, pkgs, ... }:

{
  services.roundcube = {
    enable = true;
    hostName = "webmail.est.unixpimps.net";
    plugins = [
      "managesieve"
      "markasjunk"
      "identity_select"
      "additional_message_headers"
      "show_additional_headers"
    ];
    extraConfig = ''
      $config['smtp_server'] = 'tls://${config.mailserver.fqdn}';
    '';
  };

  services.dovecot2 = {
    sieve.extensions = [ "fileinto" ];
    # Replaces the fork's only change: default_vsz_limit 512M -> 2G
    extraConfig = ''
      default_vsz_limit = 2G
    '';
  };

  mailserver = {
    enable = true;
    enablePop3 = true;
    enablePop3Ssl = true;
    enableManageSieve = true;
    fqdn = "pakhet.est.unixpimps.net";
    domains = [
      "shouldidrink.today"
      "perlpimp.net"
      "unixpimps.net"
      "nordic-t.me"
      "allporn.dk"
      "brugervenlig.dk"
      "depri.dk"
      "outerspace.dk"
      "perlpimp.dk"
      "syslogic.dk"
      "unixpimp.dk"
      "ddfrbr.com"
      "martin8412.dk"
    ];
    virusScanning = true;
    loginAccounts = {
      "ij@perlpimp.net" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_ij.path;
        aliases = [
          "ij@shouldidrink.today"
          "ij@unixpimps.net"
          "ij@syslogic.dk"
          "ij@perlpimp.dk"
          "ij@outerspace.dk"
          "ij@ddfrbr.com"
          "sniffy@ddfrbr.com"
        ];
      };
      "brother-hallway@unixpimps.net" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_brother_hallway.path;
      };
      "martin@martin8412.dk" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_mj.path;
        aliases = [ "mj@nordic-t.me" "mj@unixpimps.net" ];
        catchAll = [ "martin8412.dk" ];
      };
      "ij@nordic-t.me" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_ij.path;
      };
      "mj@nordic-t.me" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_mj.path;
      };
      "no-reply@unixpimps.net" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_no_reply.path;
      };
      "themailer@unixpimps.net" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_themailer.path;
      };
      "alertmanager@unixpimps.net" = {
        hashedPasswordFile = config.sops.secrets.mail_hashed_password_alertmanager.path;
      };
    };
    forwards = {
      "hello@ddfrbr.com" = [ "ij@ddfrbr.com" ];
      "sysops@unixpimps.net" = [ "ij@unixpimps.net" "mj@unixpimps.net" ];
      "hostmaster@unixpimps.net" = [ "ij@unixpimps.net" "mj@unixpimps.net" ];
      "tech@nordic-t.me" = [ "ij@nordic-t.me" "mj@nordic-t.me" ];
      "admin@nordic-t.me" = [ "ij@nordic-t.me" "mj@nordic-t.me" ];
      "sysops@nordic-t.me" = [ "ij@nordic-t.me" "mj@nordic-t.me" ];
      "hostmaster@nordic-t.me" = [ "ij@nordic-t.me" "mj@nordic-t.me" ];
      "donation@nordic-t.me" = [ "ij@nordic-t.me" ];
      "paypal@nordic-t.me" = [ "ij@nordic-t.me" ];
    };
    stateVersion = 3;
    certificateScheme = "acme-nginx";
    borgbackup = {
      enable = true;
      repoLocation = "/var/borgbackup/mail";
    };
  };
}
