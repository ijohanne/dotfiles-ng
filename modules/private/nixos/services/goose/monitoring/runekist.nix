{ inputs, network, pkgs, ... }:

let
  dashboards = pkgs.runCommand "runekist-dashboards" { } ''
    mkdir -p "$out"
    cp ${inputs.runekist + "/grafana/dashboards/runekist-scheduler-overview.json"} "$out/runekist-scheduler-overview.json"
  '';
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "runekist";
      honor_labels = true;
      metrics_path = "/metrics";
      scrape_interval = "15s";
      static_configs = [
        {
          targets = [ "${network.hosts.wg-app-srv-00-rbx-fr.ip}:9569" ];
          labels = {
            instance = "app-srv-00.rbx.fr";
            service = "runekist";
          };
        }
      ];
    }
  ];

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "runekist";
      options.path = dashboards;
    }
  ];
}
