{ network, ... }:

{
  imports = [
    ./node.nix
    ./nftables.nix
    ./smokeping.nix
    ./zfs.nix
    ./nut.nix
    ./ipmi.nix
    ./screeny.nix
    ./grpc-proxier.nix
    ./pdfdetective.nix
    ./hickory-dns.nix
    ./wireguard.nix
    ./unpoller.nix
    ./hue.nix
    ./telegraf.nix
    ./tplink-p110.nix
    ./ecowitt.nix
    ./proton-port-sync.nix
    ./vardrun.nix
    ./nginx.nix
    ./postgres.nix
    ./zot.nix
    ./uptimeplaza.nix
    ./chrony.nix
    ./gpsd.nix
  ];
}
