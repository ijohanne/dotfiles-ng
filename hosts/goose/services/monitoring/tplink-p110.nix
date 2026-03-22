{ network, config, ... }:

{
  services.prometheus-tplink-p110-exporter = {
    enable = true;
    enableLocalScraping = true;
    usernameFile = config.sops.secrets.tplink_username.path;
    passwordFile = config.sops.secrets.tplink_password.path;
    hosts = [
      network.hosts.terrace-laundry-plug.ip
      network.hosts.terrace-fridge-plug.ip
    ];
  };
}
