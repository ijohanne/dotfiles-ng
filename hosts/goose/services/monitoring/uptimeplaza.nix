{ config, inputs, pkgs, ... }:

let
  checkerTypes = [ "dns" "fping" "ping" "ssl" "http" "website-screenshot" ];

  secretName = type:
    "uptimeplaza_prometheus_${builtins.replaceStrings [ "-" ] [ "_" ] type}_targets";

  mkScrapeJob = type: {
    job_name = "uptimeplaza-${type}";
    scheme = "https";
    basic_auth = {
      username = "prometheus";
      password_file = config.sops.secrets.uptimeplaza_prometheus_password.path;
    };
    file_sd_configs = [{
      files = [ config.sops.templates."uptimeplaza-${type}-sd.json".path ];
    }];
  };

  dashboards = pkgs.runCommand "uptimeplaza-dashboards" {} (''
    mkdir -p $out
  '' + builtins.concatStringsSep "\n" (map (type:
    "cp ${inputs.${"uptimeplaza-checker-" + type}}/nix/dashboard.json $out/uptimeplaza-${type}.json"
  ) checkerTypes));
in
{
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
    };
  }) checkerTypes);

  services.prometheus.scrapeConfigs = map mkScrapeJob checkerTypes;

  services.grafana.provision.dashboards.settings.providers = [{
    name = "uptimeplaza";
    options.path = dashboards;
  }];
}
