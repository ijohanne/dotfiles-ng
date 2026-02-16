{ inputs, config, pkgs, user, ... }:

{
  imports = [
    ../../configs/secrets.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "ij-desktop";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb.layout = "us";

  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  users.users.${user.username} = {
    isNormalUser = true;
    description = user.name;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
      git
      vim
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = user.sshKeys;
  };

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  nixpkgs.overlays = [
    inputs.rust-overlay.overlays.default
  ];

  programs.fish.enable = true;

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      inter
    ];
  };

  virtualisation.docker = {
    enable = true;
  };

  system.stateVersion = "23.05";
}
