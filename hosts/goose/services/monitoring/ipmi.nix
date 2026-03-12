{ network, ... }:

{ pkgs, ... }:

let
  ipmiConfig = pkgs.writeText "ipmi-exporter.yml" ''
    modules:
      default:
        driver: "LAN_2_0"
        privilege: "admin"
        timeout: 10000
        collectors:
        - bmc
        - ipmi
        - chassis
  '';
in
{
  systemd.services.prometheus-ipmi-exporter = {
    description = "Prometheus IPMI Exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.prometheus-ipmi-exporter}/bin/ipmi_exporter --config.file=${ipmiConfig} --web.listen-address=:9290";
      Restart = "always";
      DynamicUser = true;
    };
    path = [ pkgs.freeipmi ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "ipmi";
      scrape_interval = "30s";
      metrics_path = "/ipmi";
      static_configs = [
        {
          targets = [ "${network.hosts.fatty-ipmi.ip}" ];
          labels = { instance = "fatty-ipmi"; };
        }
        {
          targets = [ "${network.hosts.goose-ipmi.ip}" ];
          labels = { instance = "goose-ipmi"; };
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "instance" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "127.0.0.1:9290";
        }
      ];
    }
  ];
}
