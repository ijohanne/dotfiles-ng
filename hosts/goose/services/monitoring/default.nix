{ network, ... }:

{
  imports = [
    (import ./node.nix { inherit network; })
    ./nftables.nix
    ./smokeping.nix
    (import ./zfs.nix { inherit network; })
    (import ./nut.nix { inherit network; })
    ./ipmi.nix
    (import ./screeny.nix { inherit network; })
    (import ./grpc-proxier.nix { inherit network; })
    (import ./pdfdetective.nix { inherit network; })
    ./unbound.nix
    ./wireguard.nix
    (import ./unpoller.nix { inherit network; })
    ./hue.nix
    ./telegraf.nix
    ./tplink-p110.nix
  ];
}
