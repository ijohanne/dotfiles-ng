{ config, pkgs, ... }:

let
  backupDir = "/var/backup/postgresql";
in
{
  sops.secrets.backup_ssh_key = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

  systemd.tmpfiles.rules = [
    "d ${backupDir} 0750 postgres postgres -"
  ];

  systemd.services.postgresql-backup = {
    description = "Dump PostgreSQL databases for Borg backup";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    path = [
      config.services.postgresql.package
      pkgs.coreutils
      pkgs.gzip
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
      UMask = "0077";
    };

    script = ''
      set -euo pipefail

      tmp="${backupDir}/.postgresql-dump.sql.gz.$$"
      final="${backupDir}/postgresql-dump.sql.gz"

      pg_dumpall | gzip -9 > "$tmp"
      mv "$tmp" "$final"
    '';
  };

  services.borgbackup.jobs.postgresql = {
    paths = backupDir;
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.backup_ssh_key.path}";
    environment.BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
    repo = "zh3691@zh3691.rsync.net:backups/seshat-postgresql";
    compression = "auto,zstd";
    startAt = "daily";
  };

  systemd.services.borgbackup-job-postgresql = {
    after = [ "postgresql-backup.service" ];
    wants = [ "postgresql-backup.service" ];
  };
}
