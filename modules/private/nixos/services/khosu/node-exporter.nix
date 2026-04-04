{ network, ... }:

{
  imports = [
    ../../../../community/nixos/services/node-exporter-base.nix
  ];

  services.prometheus.exporters.node = {
    listenAddress = "${network.hosts.wg-khosu.ip}";
  };
}
