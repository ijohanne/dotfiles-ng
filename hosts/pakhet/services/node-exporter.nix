{ network, ... }:

{ ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
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

  networking.firewall.allowedTCPPorts = [ 9100 ];
}
