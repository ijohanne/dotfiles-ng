{ lib, config, pkgs, user, users, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../configs/profiles/system/base
  ];

  networking = {
    hostName = lib.mkDefault "rpi4";
    useDHCP = true;
    wireless.enable = false;
  };

  time.timeZone = "Europe/Madrid";

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng";
  };

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

  sdImage.compressImage = false;
}
