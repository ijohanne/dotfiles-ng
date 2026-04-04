{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nginx";
      honor_labels = true;
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:9113" ];
          labels = { instance = "pakhet"; };
        }
      ];
    }
  ];
}
