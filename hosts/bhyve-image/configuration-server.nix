{ lib, config, pkgs, user, modulesPath, ... }:

{
  imports = [
    ../../configs/profiles/qemu-guest.nix
    ../../configs/profiles/grow-root-sda2.nix
    ../../configs/server.nix
  ];

  system.stateVersion = "25.11";
}
