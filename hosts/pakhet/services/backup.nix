{ config, pkgs, ... }:

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

  # Create screeny backup directory and dump database before borg backup runs
  systemd.tmpfiles.rules = [
    "d /var/backup/screeny 0750 root root -"
  ];

  systemd.services.screeny-backup = {
    description = "Backup Screeny SQLite database";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.sqlite}/bin/sqlite3 /var/lib/screeny/screeny.db \".backup '/var/backup/screeny/screeny.db'\"";
    };
  };

  systemd.timers.screeny-backup = {
    description = "Run Screeny backup before borg";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Ensure screeny backup runs before borg backup
  systemd.services.borgbackup-job-screeny = {
    after = [ "screeny-backup.service" ];
    wants = [ "screeny-backup.service" ];
  };
}
