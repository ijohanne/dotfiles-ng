{ config, inputs, ... }:

{
  sops.templates."screeny-maxmind-env" = {
    content = ''
      MAXMIND_LICENSE_KEY=${config.sops.placeholder.maxmind_api_key}
    '';
    owner = "screeny";
    group = "screeny";
    mode = "0400";
  };

  services.screeny = {
    backend = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-backend-postgres;
      host = "0.0.0.0";
      port = 3002;
      jwtSecretFile = config.sops.secrets.screeny_jwt_secret.path;
      adminPasswordFile = config.sops.secrets.screeny_admin_password.path;
      geoipDatabasePath = "/var/lib/screeny/GeoLite2-Country.mmdb";

      # Telegram bot integration
      telegram = {
        enable = true;
        botTokenFile = config.sops.secrets.screeny_telegram_bot_token.path;
        botUsername = "ScreenyApp_bot";
        useWebhook = true;  # Production mode with webhook
      };
    };

    geoip = {
      enable = true;
      licenseKeyFile = config.sops.templates."screeny-maxmind-env".path;
    };

    nginx = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-frontend;
      domain = "screeny.unixpimps.net";
      enableACME = true;
      forceSSL = true;
      frontendPort = 3001;  # Avoid conflict with Gitea on port 3000
      disableGraphiQL = true;
    };
  };
}
