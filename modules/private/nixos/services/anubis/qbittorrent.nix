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
        # PBKDF2-SHA512 hash of the plaintext password in secrets/anubis.yaml -> qbittorrent/webui_password
        # If you change the password in sops, regenerate this hash:
        #   python3 -c "import hashlib,secrets,base64; p='NEW_PASSWORD'; s=secrets.token_bytes(16); dk=hashlib.pbkdf2_hmac('sha512',p.encode(),s,100000,dklen=64); print(f'@ByteArray({base64.b64encode(s).decode()}:{base64.b64encode(dk).decode()})')"
        "WebUI\\Password_PBKDF2" = "@ByteArray(BehgM5UHfJ1+VpdszKvAhg==:mS54W9XFlq360CHikevuiAIdpCYk37u2dbsLUNAONMW6dL6WXs/lH5lIE6T7hWlH6WlVEIC2RKRHHBUku6y8tA==)";
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
