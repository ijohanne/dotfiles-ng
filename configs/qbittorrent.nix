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

  systemd.services.qbittorrent.preStart = let
    python = pkgs.python3.withPackages (ps: [ ps.passlib ]);
    setPassword = pkgs.writeScript "qbt-set-password" ''
      #!${python}/bin/python3
      import configparser, os, hashlib, secrets
      from passlib.crypto.digest import pbkdf2_hmac

      conf_path = "/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
      pw_file = "${config.sops.secrets."qbittorrent/webui_password".path}"

      password = open(pw_file).read().strip()
      salt = secrets.token_bytes(16)
      dk = pbkdf2_hmac("sha512", password.encode(), salt, 100000, 64)
      pbkdf2_str = f"@ByteArray({salt.hex()}:{dk.hex()})"

      os.makedirs(os.path.dirname(conf_path), exist_ok=True)

      cfg = configparser.ConfigParser()
      cfg.optionxform = str
      if os.path.exists(conf_path):
          cfg.read(conf_path)

      if "Preferences" not in cfg:
          cfg["Preferences"] = {}
      cfg["Preferences"]["WebUI\\Password_PBKDF2"] = pbkdf2_str

      with open(conf_path, "w") as f:
          cfg.write(f, space_around_delimiters=False)
    '';
  in ''
    ${setPassword}
  '';

  systemd.tmpfiles.rules = [
    "d /data/torrents          0755 qbittorrent qbittorrent -"
    "d /data/torrents/download 0755 qbittorrent qbittorrent -"
    "d /data/torrents/complete 0755 qbittorrent qbittorrent -"
    "d /data/torrents/watch    0755 qbittorrent qbittorrent -"
  ];
}
