{ network, ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "postgres";
      honor_labels = true;
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:9630" ];
          labels = {
            instance = "pakhet";
          };
        }
        {
          targets = [ "${network.hosts.wg-app-srv-00-rbx-fr.ip}:9630" ];
          labels = {
            instance = "app-srv-00.rbx.fr";
          };
        }
        {
          targets = [ "${network.hosts.wg-app-srv-00-nur-de.ip}:9630" ];
          labels = {
            instance = "app-srv-00.nur.de";
          };
        }
        {
          targets = [ "${network.hosts.wg-collector-00-muc-de.ip}:9630" ];
          labels = {
            instance = "collector-00-muc-de";
          };
        }
      ];
    }
  ];
}
