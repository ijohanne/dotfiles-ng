{ network, config, ... }:

{
  services.prometheus-hue-exporter = {
    main = {
      enable = true;
      enableLocalScraping = true;
      port = 9773;
      hueUrl = network.hosts.main-bridge.ip;
      hueApiKeyFile = config.sops.secrets.hue_api_key.path;
    };
    secondary = {
      enable = true;
      enableLocalScraping = true;
      port = 9774;
      hueUrl = network.hosts.secondary-bridge.ip;
      hueApiKeyFile = config.sops.secrets.hue_api_key_secondary.path;
    };
  };
}
