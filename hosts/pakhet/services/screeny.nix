{ config, inputs, ... }:

{
  services.screeny = {
    backend = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-backend;
      jwtSecretFile = config.sops.secrets.screeny_jwt_secret.path;
      adminPasswordFile = config.sops.secrets.screeny_admin_password.path;
    };

    nginx = {
      enable = true;
      package = inputs.screeny.packages.x86_64-linux.screeny-frontend;
      domain = "screeny.unixpimps.net";
      enableACME = true;
      forceSSL = true;
    };
  };
}
