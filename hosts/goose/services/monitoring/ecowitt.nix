{ ... }:

{
  services.prometheus-ecowitt-exporter = {
    enable = true;
    enableLocalScraping = true;
    enableGrafanaDashboard = true;
  };
}
