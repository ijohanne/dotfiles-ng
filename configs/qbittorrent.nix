{ config, pkgs, lib, ... }:

{
  services.qbittorrent = {
    enable = true;
    webuiPort = 8080;
    torrentingPort = 49160;
    user = "qbittorrent";
    group = "qbittorrent";
    openFirewall = false;

    serverConfig = {
      BitTorrent.Session = {
        DefaultSavePath = "/data/torrents/complete";
        TempPath = "/data/torrents/download";
        TempPathEnabled = true;
        Interface = "wg0";
        InterfaceName = "wg0";
        Port = 0;
      };
      Preferences = {
        "WebUI\\Address" = "127.0.0.1";
        "Connection\\UPnP" = false;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/torrents          0755 qbittorrent qbittorrent -"
    "d /data/torrents/download 0755 qbittorrent qbittorrent -"
    "d /data/torrents/complete 0755 qbittorrent qbittorrent -"
    "d /data/torrents/watch    0755 qbittorrent qbittorrent -"
  ];
}
