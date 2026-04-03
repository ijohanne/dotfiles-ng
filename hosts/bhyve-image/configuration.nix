{ lib, config, pkgs, user, users, modulesPath, ... }:

{
  imports = [
    ../../configs/profiles/system/base
    ../../configs/profiles/system/qemu-guest
    ../../configs/profiles/system/grow-root-sda2
  ];

  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  users.users = lib.mapAttrs
    (_: u: {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = u.sshKeys;
    })
    users // {
    root = {
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = lib.concatMap (u: u.sshKeys) (lib.attrValues users);
    };
  };

  system.stateVersion = "25.11";
}
