{ config, inputs, pkgs, lib, ... }:

let
  cfg = config.services.opsplaza;
  themailerImage = inputs.opsplaza.packages.x86_64-linux.themailerImage;

  couchdb-dump = pkgs.fetchFromGitHub {
    owner = "danielebailo";
    repo = "couchdb-dump";
    rev = "master";
    sha256 = "sha256-nL1ZYUEl9tSic0KyteB9RfGUjUY3qKZsDURBBaZ+6XA=";
  };
in
{
  options.services.opsplaza.enable = lib.mkEnableOption "opsplaza themailer service";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules = [
      "d /var/opsplaza/couchdb 0700 root root"
      "d /var/backup/opsplaza 0700 root root"
    ];

    # Podman network for opsplaza containers
    systemd.services.init-opsplaza-podman-network = {
      description = "Create the podman network for opsplaza";
      after = [ "podman.service" ];
      requires = [ "podman.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.podman}/bin/podman network create opsplaza-br || true
      '';
    };

    virtualisation.oci-containers.containers = {
      couchdb = {
        image = "couchdb:2.3.1";
        ports = [ "127.0.0.1:5984:5984" ];
        volumes = [ "/var/opsplaza/couchdb:/opt/couchdb/data" ];
        extraOptions = [ "--network=opsplaza-br" ];
      };

      themailer = {
        imageFile = themailerImage;
        image = "themailer:latest";
        ports = [ "127.0.0.1:12001:8080" ];
        extraOptions = [ "--network=opsplaza-br" ];
      };

      themailerpostfix = {
        image = "boky/postfix:latest";
        extraOptions = [ "--network=opsplaza-br" ];
        environment = {
          RELAYHOST = "host.containers.internal:587";
          RELAYHOST_USERNAME = "themailer@unixpimps.net";
          ALLOWED_SENDER_DOMAINS = "opsplaza.com ragetech.dk";
        };
        environmentFiles = [
          config.sops.templates."opsplaza-postfix-env".path
        ];
      };
    };

    sops.templates."opsplaza-postfix-env" = {
      content = ''
        RELAYHOST_PASSWORD=${config.sops.placeholder.opsplaza_smtp_pass}
      '';
      mode = "0400";
    };

    # Ensure containers start after the network is created
    systemd.services.podman-couchdb = {
      after = [ "init-opsplaza-podman-network.service" ];
      requires = [ "init-opsplaza-podman-network.service" ];
    };

    systemd.services.podman-themailer = {
      after = [ "init-opsplaza-podman-network.service" "podman-couchdb.service" ];
      requires = [ "init-opsplaza-podman-network.service" ];
    };

    systemd.services.podman-themailerpostfix = {
      after = [ "init-opsplaza-podman-network.service" ];
      requires = [ "init-opsplaza-podman-network.service" ];
    };

    # Nginx vhost
    services.nginx.virtualHosts."themailer.opsplaza.com" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:12001";
        extraConfig = ''
          proxy_set_header Host themailer.ragetech.dk;
        '';
      };
    };

    # CouchDB backup
    systemd.services.opsplaza-couchdb-backup = {
      description = "Backup opsplaza CouchDB";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "opsplaza-couchdb-backup" ''
          ${pkgs.bash}/bin/bash ${couchdb-dump}/couchdb-dump.sh \
            -b -H 127.0.0.1 -P 5984 -d themailer \
            -f /var/backup/opsplaza/themailer-$(date +%Y%m%d).json
          # Keep only last 7 backups
          ls -t /var/backup/opsplaza/themailer-*.json 2>/dev/null | tail -n +8 | xargs -r rm
        '';
      };
    };

    systemd.timers.opsplaza-couchdb-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";
        Persistent = true;
      };
    };

    # Borgbackup
    services.borgbackup.jobs.opsplaza = {
      paths = "/var/backup/opsplaza";
      encryption.mode = "none";
      environment.BORG_RSH = "ssh -i ${config.sops.secrets.backup_ssh_key.path}";
      environment.BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
      repo = "zh3691@zh3691.rsync.net:backups/opsplaza";
      compression = "auto,zstd";
      startAt = "daily";
    };

    systemd.services.borgbackup-job-opsplaza = {
      after = [ "opsplaza-couchdb-backup.service" ];
      wants = [ "opsplaza-couchdb-backup.service" ];
    };
  };
}
