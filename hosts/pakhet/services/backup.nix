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
}
