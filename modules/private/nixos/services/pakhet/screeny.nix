{ config, inputs, network, pkgs, ... }:

let
  chestCounterName = "k111_agw_main";
  chestCounterDomain = "k111-agw-main-chest-counter.${network.domain}";
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
          endpointUrl = "http://${chestCounterDomain}";
          sourceId = chestCounterName;
          apiKeyFile = config.sops.secrets.screeny_k111_agw_chest_counter_api_key.path;

          scheduler = {
            maxRowsPerRun = 50;
            runIntervalSecs = 300;
            lowYieldRunIntervalSecs = 600;
            lowYieldThresholdPercent = 50;
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

    chestCounterCollectors.${chestCounterName} = {
      package = inputs.screeny.packages.${pkgs.stdenv.hostPlatform.system}.screeny-chest-counter;

      sourceId = chestCounterName;
      apiKeyFile = config.sops.secrets.screeny_k111_agw_chest_counter_api_key.path;
      domain = chestCounterDomain;

      totalBattle = {
        login = "ij@unixpimps.net";
        passwordFile = config.sops.secrets.screeny_k111_agw_chest_counter_tb_password.path;
      };

      email2fa = {
        enable = true;
        imapServer = "imap.unixpimps.net";
        imapPort = 993;
        username = "ij@unixpimps.net";
        passwordFile = config.sops.secrets.screeny_k111_agw_chest_counter_mail_pass.path;
        inboxFolder = "INBOX";
        useTls = true;
        useStartTls = false;
        senderFilter = "noreply@service.totalbattle.com";
      };

      database = {
        type = "postgres";
        postgres = {
          host = null;
          socketPath = "/run/postgresql";
          database = "chest_counter_k111_agw_main";
          user = "chest_counter_k111_agw_main";
        };
      };

      browser = {
        headless = true;
        captureDebugScreenshots = false;
        captureRewardProbe = false;
        extraArgs = [
          "--use-gl=angle"
          "--use-angle=swiftshader-webgl"
          "--enable-unsafe-swiftshader"
        ];
      };

      artifacts.policy = "failures";

      scheduler = {
        maxRowsPerRun = 50;
        runIntervalSecs = 300;
        lowYieldRunIntervalSecs = 600;
        lowYieldThresholdPercent = 50;
      };

      ocr.workerConcurrency = 1;

      service = {
        cpuQuota = "100%";
        cpuWeight = 20;
        nice = 10;
      };

      prometheusLabels = {
        clan = chestCounterName;
        service = "chest-counter";
      };
    };
  };

  services.nginx.virtualHosts.${chestCounterDomain}.locations."/".extraConfig = ''
    allow 10.0.0.0/8;
    allow fd00:255::/48;
    deny all;
  '';
}
