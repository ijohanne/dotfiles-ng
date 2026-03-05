{ network, ... }:

{ config, ... }:

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
}
