{ ... }:

{
  services.grpc-proxier = {
    instances.node-cctax = {
      listenPort = 4001;
      upstreamAddress = "10.255.101.245:20000";
      metricsAddress = "0.0.0.0";
      metricsPort = 9090;
      noAuth = true;

      nginx = {
        enable = true;
        domain = "cctax.grpc.unixpimps.net";
        acme = true;
      };
    };
  };
}
