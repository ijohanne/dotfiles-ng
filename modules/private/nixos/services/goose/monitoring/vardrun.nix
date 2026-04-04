{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "vardrun";
      honor_labels = true;
      metrics_path = "/metrics";
      scrape_interval = "15s";
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:4002" ];
          labels.instance = "unixpimps";
        }
        {
          targets = [ "${network.hosts.pakhet.ip}:4012" ];
          labels.instance = "opsplaza";
        }
      ];
    }
  ];
}
