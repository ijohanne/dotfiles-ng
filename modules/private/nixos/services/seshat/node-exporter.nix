{ network, modules, ... }:

{
  imports = [
    modules.public.nixos.services.nodeExporterBase
  ];

  services.prometheus.exporters.node.listenAddress = network.hosts.wg-seshat.ip;
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9100 ];
}
