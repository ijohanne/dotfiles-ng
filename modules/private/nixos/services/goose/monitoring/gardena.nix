{ config, ... }:

{
  services.prometheus-gardena-exporter = {
    enable = true;
    enableLocalScraping = true;
    enableGrafanaDashboard = true;
    estimatedFlowLitersPerMinute = 0.2;
    applicationKeyFile = config.sops.secrets.gardena_api_key.path;
    applicationSecretFile = config.sops.secrets.gardena_api_secret.path;
  };
}
