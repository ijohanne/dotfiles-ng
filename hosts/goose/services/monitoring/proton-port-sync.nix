{ network, ... }:

{ ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "proton-port-sync";
      honor_labels = true;
      static_configs = [
        {
          targets = [ "${network.hosts.wg-anubis.ip}:9834" ];
          labels = { instance = "anubis"; };
        }
      ];
    }
  ];
}
