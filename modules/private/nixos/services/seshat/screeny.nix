{ config, inputs, network, ... }:

let
  collectorName = "k111-agw";
  collectorUser = "chest_counter_k111_agw";
  collectorPort = 8090;
in
{
  sops.secrets.screeny_k111_agw_chest_counter_api_key = {
    mode = "0400";
    owner = collectorUser;
    group = "screeny";
  };

  sops.secrets.screeny_k111_agw_chest_counter_tb_password = {
    mode = "0400";
    owner = collectorUser;
    group = "screeny";
  };

  sops.secrets.screeny_k111_agw_chest_counter_mail_pass = {
    mode = "0400";
    owner = collectorUser;
    group = "screeny";
  };

  services.screeny.chestCounterCollectors.${collectorName} = {
    package = inputs.screeny.packages.x86_64-linux.screeny-chest-counter;
    sourceId = "k111_agw_main";
    apiKeyFile = config.sops.secrets.screeny_k111_agw_chest_counter_api_key.path;

    listen = {
      host = network.hosts.wg-seshat.ip;
      port = collectorPort;
    };

    database.type = "postgres";

    totalBattle = {
      login = "ij@unixpimps.net";
      passwordFile = config.sops.secrets.screeny_k111_agw_chest_counter_tb_password.path;
    };

    browser = {
      viewport = {
        width = 1920;
        height = 1080;
      };
      openClanPoint = {
        x = 1043;
        y = 982;
      };
      openGiftsPoint = {
        x = 540;
        y = 408;
      };
      giftsTabPoint = {
        x = 855;
        y = 342;
      };
      giftsTabFallbackPoint = {
        x = 855;
        y = 349;
      };
      triumphalGiftsTabPoint = {
        x = 1059;
        y = 342;
      };
      triumphalGiftsTabFallbackPoint = {
        x = 1123;
        y = 349;
      };
      giftsList = {
        openRowPoint = {
          x = 1348;
          y = 436;
        };
        rowCapture = {
          firstRowRegion = {
            x = 690;
            y = 372;
            width = 760;
            height = 100;
          };
          rowPitchY = 100;
          rowCount = 4;
        };
      };
      giftsTabSwatches = {
        giftsRegion = {
          x = 722;
          y = 328;
          width = 24;
          height = 14;
        };
        triumphalRegion = {
          x = 1019;
          y = 328;
          width = 24;
          height = 14;
        };
      };
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

    scheduler = {
      runIntervalSecs = 900;
      lowYieldRunIntervalSecs = 900;
      maxRowsPerRun = 500;
    };

    ocr.workerConcurrency = 1;

    prometheusLabels = {
      clan = "K111-AGW";
      service = "chest-counter";
    };

    service = {
      cpuQuota = "150%";
      cpuWeight = 20;
      nice = 10;
    };
  };
}
