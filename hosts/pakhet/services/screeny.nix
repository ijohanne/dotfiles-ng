{ config, inputs, ... }:

{
  sops.templates."screeny-maxmind-env" = {
    content = ''
      MAXMIND_LICENSE_KEY=${config.sops.placeholder.maxmind_api_key}
    '';
    owner = "screeny";
    group = "screeny";
    mode = "0400";
  };

  services.screeny = {
    frontendPackage = inputs.screeny.packages.x86_64-linux.screeny-frontend;

    # Existing clan — migrated from flat config
    instances.k111-agw = {
      domain = "screeny.unixpimps.net";

      backend = {
        host = "0.0.0.0";
        port = 3002;
        databaseType = "postgres";
        # postgres.database defaults to "screeny_k111_agw"
        # NOTE: Requires one-time DB rename on deploy:
        #   sudo -u postgres psql -c "ALTER DATABASE screeny RENAME TO screeny_k111_agw;"
        jwtSecretFile = config.sops.secrets.screeny_k111_agw_jwt_secret.path;
        adminPasswordFile = config.sops.secrets.screeny_k111_agw_admin_password.path;
        geoipDatabasePath = "/var/lib/screeny/GeoLite2-Country.mmdb";

        telegram = {
          enable = true;
          botTokenFile = config.sops.secrets.screeny_k111_agw_telegram_bot_token.path;
          botUsername = "ScreenyApp_bot";
          useWebhook = true;
        };
      };

      frontendPort = 3001;

      nginx = {
        enableACME = true;
        forceSSL = true;
        disableGraphiQL = true;
      };

      backup = {
        enable = true;
        schedule = "daily";
      };
    };

    # K131-GoD clan — new instance, empty database
    instances.k131-god = {
      domain = "screeny-god.unixpimps.net";

      backend = {
        host = "0.0.0.0";
        port = 3004;
        databaseType = "postgres";
        # postgres.database defaults to "screeny_k131_god"
        jwtSecretFile = config.sops.secrets.screeny_k131_god_jwt_secret.path;
        adminPasswordFile = config.sops.secrets.screeny_k131_god_admin_password.path;
      };

      frontendPort = 3003;

      nginx = {
        enableACME = true;
        forceSSL = true;
        disableGraphiQL = true;
      };

      backup = {
        enable = true;
        schedule = "daily";
      };
    };

    geoip = {
      enable = true;
      licenseKeyFile = config.sops.templates."screeny-maxmind-env".path;
    };
  };
}
