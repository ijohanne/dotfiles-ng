{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "zot";
      honor_labels = true;
      metrics_path = "/metrics";
      basic_auth = {
        username = "prometheus";
        password = "prometheus";
      };
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:5000" ];
          labels = { instance = "pakhet"; };
        }
      ];
    }
  ];
}
