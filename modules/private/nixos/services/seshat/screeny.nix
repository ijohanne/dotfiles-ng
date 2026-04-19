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

    browser.profile = {
      enable = true;
      resetOnLaunch = false;
      cleanRetryOnFailure = true;
    };

    browser.backend = "playwright-sidecar";

    browser.networkObservability = {
      enable = false;
      eventLog = {
        enable = false;
        capturePayloads = true;
        maxPayloadBytes = 200000;
      };
      rubens = {
        enable = true;
        interRowFastPath.enable = true;
      };
    };

    database.type = "postgres";

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

    scheduler = {
      maxRowsPerRun = 2000;
      runIntervalSecs = 60;
      failedRunRetryIntervalSecs = 60;
      lowYieldRunIntervalSecs = 600;
      lowYieldThresholdPercent = 0;
    };

    ocr.workerConcurrency = 1;

    prometheusLabels = {
      clan = "K111-AGW";
      service = "chest-counter";
    };
  };
}
