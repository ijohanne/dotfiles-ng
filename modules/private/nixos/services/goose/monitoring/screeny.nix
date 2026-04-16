{ inputs, network, pkgs, ... }:

let
  dashboards = pkgs.runCommand "screeny-dashboards" { } ''
    mkdir -p "$out"
    cp ${inputs.screeny + "/docs/grafana-dashboard.json"} "$out/screeny.json"
  '';
in
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
          labels = {
            clan = "k111_agw_main";
            service = "screeny";
          };
        }
        {
          targets = [ "${network.hosts.pakhet.ip}:3004" ];
          labels = {
            clan = "K131-GOD";
            service = "screeny";
          };
        }
      ];
    }
    {
      job_name = "screeny-chest-counter";
      honor_labels = true;
      metrics_path = "/metrics";
      scrape_interval = "15s";
      static_configs = [
        {
          targets = [ "k111-agw-main-chest-counter.${network.domain}:80" ];
          labels = {
            clan = "k111_agw_main";
            collector = "k111_agw_main";
            service = "chest-counter";
            source_id = "k111_agw_main";
          };
        }
      ];
    }
  ];

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "screeny";
      options.path = dashboards;
    }
  ];
}
