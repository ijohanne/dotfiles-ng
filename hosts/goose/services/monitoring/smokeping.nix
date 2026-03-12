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

  systemd.services.prometheus-smokeping-exporter = {
    after = [ "unbound.service" ];
    requires = [ "unbound.service" ];
    serviceConfig = {
      RestartSec = 5;
      StartLimitIntervalSec = 60;
      StartLimitBurst = 10;
    };
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
