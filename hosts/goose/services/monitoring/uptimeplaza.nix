{ config, inputs, pkgs, ... }:

let
  checkerTypes = [ "dns" "fping" "ping" "ssl" "http" "website-screenshot" ];

  sdDir = "/var/lib/prometheus2/file_sd";

  secretName = type:
    "uptimeplaza_prometheus_${builtins.replaceStrings [ "-" ] [ "_" ] type}_targets";

  mkScrapeJob = type: {
    job_name = "checker-${type}";
    scheme = "https";
    basic_auth = {
      username = "prometheus";
      password_file = config.sops.secrets.uptimeplaza_prometheus_password.path;
    };
    file_sd_configs = [{
      files = [ "${sdDir}/uptimeplaza-${type}.json" ];
    }];
  };

  dashboards = pkgs.runCommand "uptimeplaza-dashboards" {} (''
    mkdir -p $out
  '' + builtins.concatStringsSep "\n" (map (type:
    "cp ${inputs.${"uptimeplaza-checker-" + type}}/nix/dashboard.json $out/uptimeplaza-${type}.json"
  ) checkerTypes));
in
{
  systemd.tmpfiles.rules = [
    "d ${sdDir} 0755 prometheus prometheus -"
  ];

  sops.secrets = {
    uptimeplaza_prometheus_password = { owner = "prometheus"; };
  } // builtins.listToAttrs (map (type: {
    name = secretName type;
    value = {};
  }) checkerTypes);

  sops.templates = builtins.listToAttrs (map (type: {
    name = "uptimeplaza-${type}-sd.json";
    value = {
      content = config.sops.placeholder.${secretName type};
      owner = "prometheus";
      path = "${sdDir}/uptimeplaza-${type}.json";
    };
  }) checkerTypes);

  services.prometheus.scrapeConfigs = map mkScrapeJob checkerTypes;

  services.grafana.provision.dashboards.settings.providers = [{
    name = "uptimeplaza";
    options.path = dashboards;
  }];
}
