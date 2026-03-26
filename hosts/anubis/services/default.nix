{ network, ... }:

{
  imports = [
    ./wireguard.nix
    ./nginx.nix
    ./qbittorrent.nix
    ./proton-port-sync.nix
    (import ../../../configs/wireguard-watchdog.nix { interface = "wg1"; })
  ];
}
