{ inputs, network, pkgs, ... }:

let
  dashboards = pkgs.runCommand "hrafnsyn-dashboards" { } ''
    mkdir -p "$out"
    cp ${inputs.ijohanne-nur.legacyPackages.${pkgs.system}.hrafnsyn.src + "/grafana/dashboards/hrafnsyn-overview.json"} "$out/hrafnsyn-overview.json"
  '';
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "hrafnsyn";
      honor_labels = true;
      metrics_path = "/metrics";
      scrape_interval = "15s";
      static_configs = [
        {
          targets = [ "${network.hosts.pakhet.ip}:4022" ];
          labels.instance = "hrafnsyn.unixpimps.net";
        }
      ];
    }
  ];

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "hrafnsyn";
      options.path = dashboards;
    }
  ];
}
