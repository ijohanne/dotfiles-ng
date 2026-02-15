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

    instances.k111-agw = {
      domain = "screeny.unixpimps.net";
      clanType = "main";

      backend = {
        host = "0.0.0.0";
        port = 3002;
        databaseType = "postgres";
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

    instances.k111-test = {
      domain = "screeny-test.unixpimps.net";
      clanType = "main";

      backend = {
        host = "0.0.0.0";
        port = 3006;
        databaseType = "postgres";
        jwtSecretFile = config.sops.secrets.screeny_k111_test_jwt_secret.path;
        adminPasswordFile = config.sops.secrets.screeny_k111_test_admin_password.path;
        questionnairesEnabled = true;
      };

      frontendPort = 3005;

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

    instances.k131-god = {
      domain = "screeny-god.unixpimps.net";
      clanType = "main";

      backend = {
        host = "0.0.0.0";
        port = 3004;
        databaseType = "postgres";
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

    microEvents = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-backend-sqlite;
    };

    geoip = {
      enable = true;
      licenseKeyFile = config.sops.templates."screeny-maxmind-env".path;
    };

    tbhub = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.tbhub;
      domain = "tb.unixpimps.net";
    };
  };
}
