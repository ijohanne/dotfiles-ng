{ lib, pkgs, ... }:

{
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
