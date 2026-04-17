{ inputs, network, pkgs, ... }:

let
  dashboards = pkgs.runCommand "screeny-dashboards" { } ''
    mkdir -p "$out"
    cp ${inputs.screeny + "/docs/grafana-dashboard.json"} "$out/screeny-backend.json"
    cp ${inputs.screeny + "/docs/grafana-chest-counter-dashboard.json"} "$out/screeny-chest-counter.json"
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
            clan = "K111-AGW";
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
          targets = [ "${network.hosts.wg-seshat.ip}:8090" ];
          labels = {
            collector = "seshat";
            clan = "K111-AGW";
	    source = "K111-AGW-MAIN";
            source_id = "k111_agw_main";
            service = "chest-counter";
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
