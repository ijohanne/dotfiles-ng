{ network, config, ... }:

{
  services.prometheus.exporters.unpoller = {
    enable = true;
    controllers = [
      {
        user = "unpoller";
        pass = config.sops.secrets.unpoller_password.path;
        url = "https://${network.hosts.cloudkey.ip}";
        verify_ssl = false;
      }
    ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "unpoller";
      honor_labels = true;
      static_configs = [{
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.unpoller.port}" ];
      }];
    }
  ];
}
