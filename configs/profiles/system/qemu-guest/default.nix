{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking = {
    hostName = lib.mkDefault "nixos";
    useDHCP = true;
  };

  time.timeZone = "Europe/Madrid";
}
