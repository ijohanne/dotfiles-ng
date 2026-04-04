{ config, ... }:

{
  services.telegraf = {
    enable = true;
    environmentFiles = [ config.sops.templates."telegraf-env".path ];
    extraConfig = {
      outputs.prometheus_client = {
        metric_version = 2;
        listen = ":9273";
        collectors_exclude = [ "gocollector" "process" ];
        export_timestamp = false;
      };
      inputs.fireboard.auth_token = "$FIREBOARD_TOKEN";
    };
  };

  sops.templates."telegraf-env" = {
    content = "FIREBOARD_TOKEN=${config.sops.placeholder.fireboard_token}";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "telegraf";
      honor_labels = true;
      static_configs = [{
        targets = [ "127.0.0.1:9273" ];
      }];
    }
  ];
}
