{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "zfs";
      honor_labels = true;
      static_configs = [{
        targets = [ "${network.hosts.fatty.ip}:9134" ];
      }];
    }
  ];
}
