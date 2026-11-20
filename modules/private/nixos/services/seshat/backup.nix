{ config, lib, pkgs, ... }:

{
  sops.secrets.backup_ssh_key = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

  programs.ssh.knownHosts."zh3691.rsync.net".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJtclizeBy1Uo3D86HpgD3LONGVH0CJ0NT+YfZlldAJd";

  services.borgbackup.jobs.postgresql = {
    # Borg interprets these arguments as the dump command and aborts the archive if it fails.
    paths = [
      "--"
      (lib.getExe' pkgs.util-linux "runuser")
      "-u"
      "postgres"
      "--"
      (lib.getExe' config.services.postgresql.package "pg_dumpall")
    ];
    extraCreateArgs = ''
      --content-from-command
      --stdin-name var/backup/postgresql/postgresql-dump.sql
      --stdin-user postgres
      --stdin-group postgres
      --stdin-mode 0600
    '';
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.backup_ssh_key.path}";
    environment.BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
    repo = "zh3691@zh3691.rsync.net:backups/seshat-postgresql";
    compression = "auto,zstd";
    prune.keep.daily = 7;
    startAt = "daily";
  };

  systemd.services.borgbackup-job-postgresql = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };
}
