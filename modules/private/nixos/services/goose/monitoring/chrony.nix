{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "chrony";
      static_configs = [{
        targets = [ "${network.hosts.chronos-wired.ip}:9123" ];
        labels = { instance = "chronos"; };
      }];
    }
  ];
}
