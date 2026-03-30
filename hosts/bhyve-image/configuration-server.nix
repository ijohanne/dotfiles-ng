{ lib, config, pkgs, user, modulesPath, ... }:

{
  imports = [
    ../../configs/profiles/system/qemu-guest
    ../../configs/profiles/system/grow-root-sda2
    ../../configs/server.nix
  ];

  system.stateVersion = "25.11";
}
