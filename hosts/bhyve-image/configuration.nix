{ lib, config, pkgs, user, users, modulesPath, modules, ... }:

{
  imports = [
    modules.public.nixos.profiles.system.base
    modules.public.nixos.profiles.system.qemuGuest
    modules.public.nixos.profiles.system.growRootSda2
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
