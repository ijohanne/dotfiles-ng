{ lib, ... }:

{
  imports = [
    ../base.nix
  ];

  networking.hostName = lib.mkForce "rpi4-stable";

  system.stateVersion = "25.05";
}
