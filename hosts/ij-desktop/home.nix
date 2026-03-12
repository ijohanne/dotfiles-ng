{ config, pkgs, lib, user, ... }:

{
  imports = [
    (import ../../configs/users/ij.nix { desktop = true; })
  ];

  home.stateVersion = "23.05";
}
