{ network, modules, ... }:

{
  imports = [
    ../nginx-security.nix
    ./wireguard.nix
    ./node-exporter.nix
    ./nginx.nix
    ./qbittorrent.nix
    ./proton-port-sync.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg1"; })
  ];
}
