{ lib, config, pkgs, user, modulesPath, ... }:

{
  imports = [
    ../../configs/profiles/system/qemu-guest
    ../../configs/profiles/system/grow-root-sda2
    ../../modules/community/nixos/aspects/server-base.nix
  ];

  system.stateVersion = "25.11";
}
