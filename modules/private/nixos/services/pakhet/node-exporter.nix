{ network, ... }:

{
  imports = [
    ../../../../community/nixos/services/node-exporter-base.nix
  ];

  networking.firewall.allowedTCPPorts = [ 9100 ];
}
