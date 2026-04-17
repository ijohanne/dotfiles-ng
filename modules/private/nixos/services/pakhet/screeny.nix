{ config, inputs, network, ... }:

let
  chestCollectorUrl = "http://${network.hosts.wg-seshat.ip}:8090";
in

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
    instances.k111-agw = {
      domain = "screeny.unixpimps.net";
      clanType = "main";
      frontendPackage = inputs.screeny.packages.x86_64-linux.screeny-frontend;

      backend = {
        package = inputs.screeny.packages.x86_64-linux.screeny-backend-postgres;
        host = "0.0.0.0";
        port = 3002;
        databaseType = "postgres";
        jwtSecretFile = config.sops.secrets.screeny_k111_agw_jwt_secret.path;
        adminPasswordFile = config.sops.secrets.screeny_k111_agw_admin_password.path;
        geoipDatabasePath = "/var/lib/screeny/GeoLite2-Country.mmdb";

        questionnairesEnabled = true;
        layoutsEnabled = true;
        layoutCalculatorVersions = [ "V2" ];
        chestCounterEnabled = true;

        chest.googleApiKeyFile = config.sops.secrets.screeny_k111_agw_google_api_key.path;
        chest.remoteCollector = {
          enable = true;
          endpointUrl = chestCollectorUrl;
          sourceId = "k111_agw_main";
          apiKeyFile = config.sops.secrets.screeny_k111_agw_chest_counter_api_key.path;
          scheduler = {
            runIntervalSecs = 900;
            lowYieldRunIntervalSecs = 900;
            maxRowsPerRun = 500;
          };
        };

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

      analytics.plausible.enable = true;

      backup = {
        enable = true;
        schedule = "daily";
      };
    };

    instances.k111-test = {
      domain = "screeny-test.unixpimps.net";
      clanType = "main";
      frontendPackage = inputs.screeny.packages.x86_64-linux.screeny-frontend;

      backend = {
        package = inputs.screeny.packages.x86_64-linux.screeny-backend-postgres;
        host = "0.0.0.0";
        port = 3006;
        databaseType = "postgres";
        jwtSecretFile = config.sops.secrets.screeny_k111_test_jwt_secret.path;
        adminPasswordFile = config.sops.secrets.screeny_k111_test_admin_password.path;
        questionnairesEnabled = true;
        layoutsEnabled = true;
      };

      frontendPort = 3007;

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
      frontendPackage = inputs.screeny.packages.x86_64-linux.screeny-frontend;

      backend = {
        package = inputs.screeny.packages.x86_64-linux.screeny-backend-postgres;
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

    geoip = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-backend-postgres;
      licenseKeyFile = config.sops.templates."screeny-maxmind-env".path;
    };

    tbhub = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.tbhub;
      domain = "tb.unixpimps.net";
      analytics.plausible.enable = true;
    };

    chestCounterControl = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-chest-counter;
      domain = "screeny-chestadm.unixpimps.net";

      users.ij.passwordHashFile = config.sops.secrets.screeny_control_user_ij_pass.path;

      remotes.k111-agw = {
        baseUrl = chestCollectorUrl;
        apiKeyFile = config.sops.secrets.screeny_k111_agw_chest_counter_api_key.path;
      };

      nginx = {
        enableACME = true;
        forceSSL = true;
      };
    };
  };
}
