{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "postgres";
      honor_labels = true;
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:9630" ];
          labels = { instance = "pakhet"; };
        }
      ];
    }
  ];
}
