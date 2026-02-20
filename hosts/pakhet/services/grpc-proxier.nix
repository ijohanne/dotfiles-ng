{ config, ... }:

{
  services.grpc-proxier = {
    instances.node-cctax = {
      listenPort = 4001;
      upstreamAddress = "10.255.101.245:20000";
      metricsAddress = "0.0.0.0";
      metricsPort = 9090;

      users.admin = {
        allowedCalls = [ "*" ];
        passwordFile = config.sops.secrets.grpc_proxier_cctax_admin_password.path;
      };

      nginx = {
        enable = true;
        domain = "cctax.grpc.unixpimps.net";
        acme = true;
      };
    };
  };
}
