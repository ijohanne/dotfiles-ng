{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nut";
      honor_labels = true;
      metrics_path = "/ups_metrics";
      static_configs = [
        {
          targets = [ "${network.hosts.fatty.ip}:9199" ];
          labels = { instance = "fatty"; };
        }
        {
          targets = [ "${network.hosts.chronos-wired.ip}:9199" ];
          labels = { instance = "chronos"; };
        }
      ];
    }
  ];
}
