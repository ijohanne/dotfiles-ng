{ network, ... }:
{
  services.prometheus-gpsd-exporter = {
    enable = true;
    enableLocalScraping = true;
    gpsdHost = network.hosts.chronos-wired.ip;
    ppsHistogram = true;
    offsetFromGeopoint = true;
    geopointLat = 36.4240;
    geopointLon = -5.1524;
  };
}
