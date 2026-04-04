{ network, ... }:

{
  imports = [
    ../../../../community/nixos/services/node-exporter-base.nix
  ];
}
