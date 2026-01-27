{ config, inputs, ... }:

{
  services.screeny = {
    backend = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-backend;
      jwtSecretFile = config.sops.secrets.screeny_jwt_secret.path;
      adminPasswordFile = config.sops.secrets.screeny_admin_password.path;

      # Telegram bot integration
      telegram = {
        enable = true;
        botTokenFile = config.sops.secrets.screeny_telegram_bot_token.path;
        botUsername = "ScreenyApp_bot";
        useWebhook = true;  # Production mode with webhook
      };
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
