{ inputs, ... }:

{
  services.pdf-detective = {
    metrics = {
      enable = true;
      package = inputs.pdf-detective.packages.x86_64-linux.pdf-detective-metrics;
      port = 3009;
      listenAddress = "127.0.0.1";
      metricsPort = 3010;
      metricsAddress = "0.0.0.0";
      logFormat = "json";
    };

    frontend = {
      enable = true;
      package = inputs.pdf-detective.packages.x86_64-linux.pdf-detective-frontend;
      port = 3008;
      hostname = "127.0.0.1";
    };

    nginx = {
      enable = true;
      domain = "pdf-checker.eu";
      aliases = [ "www.pdf-checker.eu" ];
      enableACME = true;
    };
  };
}
