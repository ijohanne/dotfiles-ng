{ lib, config, pkgs, user, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../configs/server.nix
  ];

  system.stateVersion = "25.11";

  networking = {
    hostName = lib.mkDefault "nixos";
    useDHCP = true;
  };

  time.timeZone = "Europe/Madrid";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  boot.growPartition = true;

  systemd.services.grow-root = {
    description = "Grow root filesystem after partition resize";
    wantedBy = [ "multi-user.target" ];
    after = [ "growpart.service" "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.e2fsprogs}/bin/resize2fs /dev/sda2";
    };
    unitConfig.ConditionPathExists = "/dev/sda2";
  };
}
