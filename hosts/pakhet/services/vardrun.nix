{ config, inputs, ... }:

{
  services.beadsDashboard = {
    package = inputs.vardrun.packages.x86_64-linux.default;

    instances.production = {
      host = "vardrun.unixpimps.net";
      port = 4000;
      metricsPort = 4002;
      grpc.port = 4003;
      listenAddress = "0.0.0.0";
      autoMigrate = true;

      secretKeyBaseFile = config.sops.secrets.vardrun_secret_key_base.path;
      jwtSecretFile = config.sops.secrets.vardrun_jwt_secret.path;
      repoSecretKeyFile = config.sops.secrets.vardrun_pat_encryption_key.path;
      defaultPatFile = config.sops.secrets.vardrun_global_pat.path;

      users = [
        {
          username = "ij";
          passwordHashFile = config.sops.secrets.vardrun_ij_password.path;
          isAdmin = true;
        }
      ];

      nginxHelper = {
        enable = true;
        enableACME = true;
      };
    };
  };
}
