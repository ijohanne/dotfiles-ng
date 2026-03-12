{ lib, config, pkgs, user, users, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  system.stateVersion = "25.11";

  networking = {
    hostName = lib.mkDefault "nixos";
    useDHCP = true;
  };

  time.timeZone = "Europe/Madrid";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    htop
    git
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

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
