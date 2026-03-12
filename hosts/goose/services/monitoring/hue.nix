{ network, ... }:

{ config, ... }:

{
  services.prometheus-hue-exporter = {
    enable = true;
    enableLocalScraping = true;
    hueUrl = network.hosts.main-bridge.ip;
    hueApiKeyFile = config.sops.secrets.hue_api_key.path;
  };
}
