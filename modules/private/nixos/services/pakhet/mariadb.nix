{ pkgs, ... }:

{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings = {
      mysqld = {
        bind-address = "127.0.0.1";
      };
    };
  };

  services.mysqlBackup = {
    enable = true;
    calendar = "02:00:00";
    location = "/var/backup/mysql";
  };
}
