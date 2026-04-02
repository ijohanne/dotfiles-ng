{ network, ... }:
{
  services.prometheus-gpsd-exporter = {
    enable = true;
    enableLocalScraping = true;
    gpsdHost = network.hosts.chronos-wired.ip;
    ppsHistogram = true;
  };
}
