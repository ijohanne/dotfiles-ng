{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nut";
      honor_labels = true;
      params.target = [ "127.0.0.1:3493" ];
      static_configs = [{
        targets = [ "${network.hosts.fatty.ip}:9995" "${network.hosts.chronos.ip}:9995" ];
      }];
    }
  ];
}
