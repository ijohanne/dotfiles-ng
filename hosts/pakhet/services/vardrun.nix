{ config, inputs, ... }:

{
  services.beadsDashboard = {
    package = inputs.vardrun.packages.x86_64-linux.default;

    instances.unixpimps = {
      host = "vardrun.unixpimps.net";
      port = 4000;
      metricsPort = 4002;
      grpc.port = 4003;
      listenAddress = "0.0.0.0";
      autoMigrate = true;

      secretKeyBaseFile = config.sops.secrets.vardrun_unixpimps_secret_key_base.path;
      jwtSecretFile = config.sops.secrets.vardrun_unixpimps_jwt_secret.path;
      repoSecretKeyFile = config.sops.secrets.vardrun_unixpimps_pat_encryption_key.path;
      defaultPatFile = config.sops.secrets.vardrun_unixpimps_global_pat.path;

      users = [
        {
          username = "ij";
          passwordHashFile = config.sops.secrets.vardrun_unixpimps_ij_password.path;
          isAdmin = true;
        }
      ];

      nginxHelper = {
        enable = true;
        enableACME = true;
      };
    };

    instances.opsplaza = {
      host = "vardrun.opsplaza.com";
      port = 4010;
      metricsPort = 4012;
      grpc.port = 4013;
      listenAddress = "0.0.0.0";
      autoMigrate = true;

      secretKeyBaseFile = config.sops.secrets.vardrun_opsplaza_secret_key_base.path;
      jwtSecretFile = config.sops.secrets.vardrun_opsplaza_jwt_secret.path;
      repoSecretKeyFile = config.sops.secrets.vardrun_opsplaza_pat_encryption_key.path;
      defaultPatFile = config.sops.secrets.vardrun_opsplaza_global_pat.path;

      users = [
        {
          username = "ij";
          passwordHashFile = config.sops.secrets.vardrun_opsplaza_ij_password.path;
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
