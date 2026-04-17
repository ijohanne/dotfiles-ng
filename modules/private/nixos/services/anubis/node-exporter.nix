{ network, modules, ... }:

{
  imports = [
    modules.public.nixos.services.nodeExporterBase
  ];

  services.prometheus.exporters.node.listenAddress = network.hosts.wg-anubis.ip;
  networking.firewall.interfaces.wg1.allowedTCPPorts = [ 9100 ];
}
