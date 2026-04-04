{ config, inputs, ... }:

{
  services.mercy = {
    enable = true;
    backendPackage = inputs.mercy.packages.x86_64-linux.mercy-backend;
    frontendPackage = inputs.mercy.packages.x86_64-linux.mercy-frontend;
    kingdoms = "20,24,27,28,29";
    scanPattern = "known";
    domain = "mercy.unixpimps.net";
    frontendPort = 3005;
    authTokenFile = config.sops.secrets.mercy_auth_token.path;
    tbEmailFile = config.sops.secrets.mercy_tb_email.path;
    tbPasswordFile = config.sops.secrets.mercy_tb_password.path;
    adminUserFile = config.sops.secrets.mercy_admin_name.path;
    adminPasswordFile = config.sops.secrets.mercy_admin_password.path;
    sessionSecretFile = config.sops.secrets.mercy_auth_token.path;
    maxDetectTasks = 4;
  };
}
