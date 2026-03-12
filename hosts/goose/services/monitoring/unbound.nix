{ config, ... }:

{
  services.prometheus.exporters.unbound = {
    enable = true;
    unbound = {
      host = "tcp://127.0.0.1:8953";
      ca = "/var/lib/unbound/unbound_server.pem";
      certificate = "/var/lib/unbound/unbound_control.pem";
      key = "/var/lib/unbound/unbound_control.key";
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "unbound";
      honor_labels = true;
      static_configs = [{
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.unbound.port}" ];
      }];
    }
  ];
}
