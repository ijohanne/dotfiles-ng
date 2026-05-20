{ config, inputs, network, ... }:

{
  sops.secrets.screeny_chest_counter_api_key = {
    mode = "0400";
    owner = "chest_counter_main";
    group = "screeny";
  };

  services.screeny.chestCounterCollectors.main = {
    package = inputs.screeny.packages.x86_64-linux.screeny-chest-counter;
    sourceId = "runekist-api-seshat";
    mode = "api-driven";
    apiKeyFile = config.sops.secrets.screeny_chest_counter_api_key.path;

    listen = {
      host = network.hosts.wg-seshat-ops.ip;
      port = 8090;
    };

    metricsListen = {
      host = network.hosts.wg-seshat.ip;
      port = 8090;
    };

    browser.backend = "playwright-sidecar";

    browser.networkObservability.rubens.giftTrace = {
      enable = true;
      captureBodies = true;
      maxBodyBytes = 65536;
      clickWindowMillis = 1500;
      listWindowMillis = 5000;
      includeClanBootstrap = false;
    };

    database.type = "postgres";
    scheduler.maxRowsPerRun = 2000;

    ocr = {
      idleWorkerConcurrency = 5;
    };
  };

  networking.firewall.interfaces.wg-ops.allowedTCPPorts = [ 8090 ];
}
