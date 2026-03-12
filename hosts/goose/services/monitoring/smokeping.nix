{ config, ... }:

{
  services.prometheus.exporters.smokeping = {
    enable = true;
    hosts = [
      "1.1.1.1"
      "8.8.8.8"
      "khosu.unixpimps.net"
    ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "smokeping";
      honor_labels = true;
      static_configs = [{
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smokeping.port}" ];
      }];
    }
  ];
}
