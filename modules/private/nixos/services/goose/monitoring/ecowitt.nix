{ ... }:

{
  services.prometheus-ecowitt-exporter = {
    enable = true;
    enableLightning = true;
    irradianceUnit = "klx";
    enableLocalScraping = true;
    enableGrafanaDashboard = true;
    forwardUrls = [ "http://10.255.240.3:8080/data/report/" ];
  };
}
