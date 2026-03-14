{ config, ... }:

{
  services.proton-port-sync = {
    enable = true;
    gateway = "10.2.0.1";
    qbtUser = "admin";
    qbtPasswordFile = config.sops.secrets."qbittorrent/webui_password".path;
    metrics = {
      enable = true;
      address = "10.100.0.10";
      port = 9834;
    };
  };
}
