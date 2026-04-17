{ network, modules, ... }:

{
  imports = [
    ./wireguard.nix
    ./node-exporter.nix
    ./nginx.nix
    ./qbittorrent.nix
    ./proton-port-sync.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg1"; })
  ];
}
