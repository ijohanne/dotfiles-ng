{ inputs, network, pkgs, ... }:

let
  dashboards = pkgs.runCommand "stripe-webhook-router-dashboards" { } ''
    mkdir -p "$out"
    cp ${inputs.stripe-router + "/grafana/dashboards/stripe-service-webhook-router.json"} "$out/stripe-webhook-router.json"
  '';
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "stripe-webhook-router";
      honor_labels = true;
      metrics_path = "/metrics";
      scrape_interval = "15s";
      static_configs = [
        {
          targets = [ "${network.hosts.wg-app-srv-00-nur-de.ip}:4100" ];
          labels = {
            instance = "app-srv-00.nur.de";
            service = "stripe-webhook-router";
          };
        }
      ];
    }
  ];

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "stripe-webhook-router";
      options.path = dashboards;
    }
  ];
}
