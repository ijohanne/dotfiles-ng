{ network, ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "${network.hosts.wg-khosu.ip}";
    enabledCollectors = [
      "cpu"
      "diskstats"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "netstat"
      "stat"
      "time"
      "vmstat"
      "systemd"
      "conntrack"
      "filefd"
      "sockstat"
    ];
  };
}
