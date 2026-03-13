{ network, ... }:

{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9001;
    retentionTime = "4320h";
    globalConfig = {
      scrape_interval = "15s";
    };
    scrapeConfigs = [
      {
        job_name = "smartctl";
        static_configs = [{
          targets = [ "${network.hosts.fatty.ip}:9633" ];
          labels = { instance = "fatty"; };
        }];
      }
      {
        job_name = "concordium-node";
        static_configs = [{
          targets = [ "${network.hosts.cctax-node.ip}:9090" ];
          labels = { instance = "cctax-node"; };
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      analytics.reporting_enabled = false;
      news.news_feed_enabled = false;
      "auth.anonymous" = {
        org_role = "Editor";
        enable = true;
      };
      server = {
        domain = "grafana.${network.domain}";
        http_port = 2342;
        http_addr = network.hosts.goose.ips.mgnt;
      };
      dashboards.default_home_dashboard_path = "${./grafana-dashboards/node-exporter.json}";
    };
    provision = {
      enable = true;
      datasources = {
        settings = {
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:9001";
              isDefault = true;
            }
          ];
        };
      };
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = ./grafana-dashboards;
        }
      ];
    };
    declarativePlugins = with pkgs.grafanaPlugins; [ grafana-piechart-panel grafana-clock-panel ];
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "grafana.${network.domain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString config.services.grafana.settings.server.http_port}";
          extraConfig = ''
            satisfy any;
            allow 10.0.0.0/8;
            deny all;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header Authorization "";
          '';
          proxyWebsockets = true;
        };
        extraConfig = ''
          auth_basic "Grafana";
          auth_basic_user_file /run/secrets-rendered/grafana-htpasswd;
        '';
      };
    };
  };

  sops.templates."grafana-htpasswd" = {
    content = "admin:${config.sops.placeholder.grafana_admin_password}";
  };
}
