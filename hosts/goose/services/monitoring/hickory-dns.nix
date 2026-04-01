{ ... }:

{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "hickory-dns";
      honor_labels = true;
      static_configs = [{
        targets = [ "127.0.0.1:9153" ];
      }];
    }
  ];
}
