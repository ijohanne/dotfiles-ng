{ lib, config, pkgs, user, users, modulesPath, ... }:

{
  imports = [
    ../../configs/profiles/base-system.nix
    ../../configs/profiles/qemu-guest.nix
    ../../configs/profiles/grow-root-sda2.nix
  ];

  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  users.users = lib.mapAttrs (_: u: {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = u.sshKeys;
  }) users // {
    root = {
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = lib.concatMap (u: u.sshKeys) (lib.attrValues users);
    };
  };

  system.stateVersion = "25.11";
}
