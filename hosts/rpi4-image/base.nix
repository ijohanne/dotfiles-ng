{ lib, config, pkgs, user, users, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  networking = {
    hostName = lib.mkDefault "rpi4";
    useDHCP = true;
    wireless.enable = false;
  };

  time.timeZone = "Europe/Madrid";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    htop
    git
  ];

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng";
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  services.xserver.enable = false;

  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

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

  sdImage.compressImage = false;
}
