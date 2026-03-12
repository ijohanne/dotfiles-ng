{ network, ... }:

{ config, ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "cpu"
      "schedstat"
      "sockstat"
      "softnet"
      "rapl"
      "powersupplyclass"
      "netclass"
      "cpufreq"
      "bcache"
      "timex"
      "conntrack"
      "diskstats"
      "entropy"
      "filefd"
      "filesystem"
      "loadavg"
      "mdadm"
      "meminfo"
      "netdev"
      "netstat"
      "stat"
      "time"
      "vmstat"
      "systemd"
      "logind"
      "interrupts"
      "ksmd"
    ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "node";
      honor_labels = true;
      static_configs = [
        {
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          labels = { instance = "goose"; };
        }
        {
          targets = [ "${network.hosts.fatty.ip}:9100" ];
          labels = { instance = "fatty"; };
        }
        {
          targets = [ "${network.hosts.pakhet.ip}:9100" ];
          labels = { instance = "pakhet"; };
        }
        {
          targets = [ "${network.hosts.wg-khosu.ip}:9100" ];
          labels = { instance = "khosu"; };
        }
      ];
    }
  ];
}
