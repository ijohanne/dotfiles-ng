{ network, ... }:

{ config, pkgs, ... }:

{
  sops.secrets.fatty_ipmi_user = {};
  sops.secrets.fatty_ipmi_pass = {};
  sops.secrets.goose_ipmi_user = {};
  sops.secrets.goose_ipmi_pass = {};

  sops.templates."ipmi-exporter.yml" = {
    content = ''
      modules:
        fatty:
          user: "${config.sops.placeholder.fatty_ipmi_user}"
          pass: "${config.sops.placeholder.fatty_ipmi_pass}"
          driver: "LAN_2_0"
          privilege: "admin"
          timeout: 10000
          collectors:
          - bmc
          - ipmi
          - chassis
        goose:
          user: "${config.sops.placeholder.goose_ipmi_user}"
          pass: "${config.sops.placeholder.goose_ipmi_pass}"
          driver: "LAN_2_0"
          privilege: "admin"
          timeout: 10000
          collectors:
          - bmc
          - ipmi
          - chassis
    '';
  };

  systemd.services.prometheus-ipmi-exporter = {
    description = "Prometheus IPMI Exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "sops-nix.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.prometheus-ipmi-exporter}/bin/ipmi_exporter --config.file=${config.sops.templates."ipmi-exporter.yml".path} --web.listen-address=:9290";
      Restart = "always";
    };
    path = [ pkgs.freeipmi ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "ipmi";
      scrape_interval = "30s";
      metrics_path = "/ipmi";
      params = { "module" = [ "fatty" ]; };
      static_configs = [
        {
          targets = [ "${network.hosts.fatty-ipmi.ip}" ];
          labels = { instance = "fatty-ipmi"; };
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
    {
      job_name = "ipmi_goose";
      scrape_interval = "30s";
      metrics_path = "/ipmi";
      params = { "module" = [ "goose" ]; };
      static_configs = [
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
