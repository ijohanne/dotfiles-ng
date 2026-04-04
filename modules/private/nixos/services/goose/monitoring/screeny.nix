{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "screeny";
      honor_labels = true;
      metrics_path = "/metrics";
      scrape_interval = "15s";
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:3002" ];
          labels = { clan = "K111-AGW"; };
        }
        {
          targets = [ "${network.hosts.pakhet.ip}:3004" ];
          labels = { clan = "K131-GOD"; };
        }
      ];
    }
  ];
}
