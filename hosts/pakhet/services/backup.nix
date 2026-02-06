{ config, ... }:

{
  services.borgbackup.jobs.mysql = {
    paths = "/var/backup/mysql";
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.backup_ssh_key.path}";
    environment.BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
    repo = "zh3691@zh3691.rsync.net:backups/mysql";
    compression = "auto,zstd";
    startAt = "daily";
  };

  services.borgbackup.jobs.screeny = {
    paths = "/var/backup/screeny";
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.backup_ssh_key.path}";
    environment.BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
    repo = "zh3691@zh3691.rsync.net:backups/screeny";
    compression = "auto,zstd";
    startAt = "daily";
  };

  systemd.services.borgbackup-job-mysql = {
    after = [ "mysql-backup.service" ];
    wants = [ "mysql-backup.service" ];
  };

  systemd.services.borgbackup-job-screeny = {
    after = [ "screeny-backup.service" ];
    wants = [ "screeny-backup.service" ];
  };
}
