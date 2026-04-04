{ lib, config, pkgs, user, modulesPath, modules, ... }:

{
  imports = [
    ../../configs/profiles/system/qemu-guest
    ../../configs/profiles/system/grow-root-sda2
    modules.public.nixos.aspects.serverBase
  ];

  system.stateVersion = "25.11";
}
