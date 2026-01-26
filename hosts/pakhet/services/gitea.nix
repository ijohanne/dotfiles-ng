{ config, pkgs, ... }:

{
  services.mysql.ensureUsers = [
    {
      name = "git";
      ensurePermissions = {
        "gitunixpimpsnet.*" = "ALL PRIVILEGES";
      };
    }
  ];

  services.gitea = {
    enable = true;
    user = "git";
    database = {
      type = "mysql";
      user = "git";
      name = "gitunixpimpsnet";
    };
    lfs.enable = true;
    settings = {
      server = {
        ROOT_URL = "https://git.unixpimps.net/";
        DOMAIN = "git.unixpimps.net";
        HTTP_ADDR = "127.0.0.1";
      };
      repository = {
        DISABLE_HTTP_GIT = false;
        USE_COMPAT_SSH_URI = true;
      };
      security = {
        INSTALL_LOCK = true;
        COOKIE_USERNAME = "gitea_username";
        COOKIE_REMEMBER_NAME = "gitea_userauth";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      session = {
        COOKIE_SECURE = true;
      };
    };
    dump = {
      enable = true;
      interval = "03:00:00";
    };
  };

  systemd.services.gitea-dump.preStart = ''
    ${pkgs.findutils}/bin/find ${config.services.gitea.dump.backupDir} -type f -mtime +7 -name '*.zip' -execdir rm -- '{}' \;
  '';

  services.nginx.virtualHosts."git.unixpimps.net" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/".proxyPass = "http://127.0.0.1:3000/";
  };

  users.users.git = {
    description = "Gitea Service";
    isNormalUser = true;
    home = config.services.gitea.stateDir;
    createHome = true;
    useDefaultShell = true;
  };
}
