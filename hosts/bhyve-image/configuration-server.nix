{ lib, config, pkgs, user, modulesPath, modules, ... }:

{
  imports = [
    modules.public.nixos.profiles.system.qemuGuest
    modules.public.nixos.profiles.system.growRootSda2
    modules.public.nixos.aspects.serverBase
  ];

  system.stateVersion = "25.11";
}
