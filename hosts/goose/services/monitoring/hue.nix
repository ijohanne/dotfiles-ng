{ ... }:

{
  #services.prometheus-hue-exporter = {
  #  enable = true;
  #  enableLocalScraping = true;
  #  hueUrl = "10.255.101.240";
  #  hueApiKey via sops: config.sops.secrets.hue_api_key.path
  #};
}
