{ lib, config, pkgs, user, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  system.stateVersion = "25.05";

  networking = {
    hostName = "rpi4";
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

  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeFunHfY3vS2izkp7fMHk2bXuaalNijYcctAF2NGc1T"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiCGBgFgwbHB+2m++ViEnhoFjww2Twvx8gXWcMvHvz3 martin@martin8412.dk"
    ];
  };

  users.users.${user.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeFunHfY3vS2izkp7fMHk2bXuaalNijYcctAF2NGc1T"
    ];
  };

  sdImage.compressImage = false;
}
