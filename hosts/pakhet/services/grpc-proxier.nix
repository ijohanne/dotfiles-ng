{ network, config, ... }:

{
  services.grpc-proxier = {
    instances.node-cctax = {
      listenPort = 4001;
      upstreamAddress = "${network.hosts.cctax-node.ip}:20000";
      metricsAddress = "0.0.0.0";
      metricsPort = 9090;

      users.admin = {
        allowedCalls = [ "*" ];
        passwordFile = config.sops.secrets.grpc_proxier_cctax_admin_password.path;
      };

      nginx = {
        domain = "cctax.grpc.unixpimps.net";
        acme = true;
      };
    };
  };
}
