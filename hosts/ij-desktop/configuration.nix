{ inputs, config, pkgs, user, modules, ... }:
{
  imports = [
    (import modules.public.nixos.aspects.gcPolicy { })
    modules.public.nixos.shared.nixCaches
    modules.private.nixos.aspects.workstationSecrets
    (import modules.public.nixos.aspects.localFlakeDeploy {
      name = "deploy-ij-desktop";
      host = "ij-desktop";
    })
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  boot.initrd.luks = {
    gpgSupport = true;
    devices.cryptroot = {
      gpgCard = {
        encryptedPass = ./luks-passphrase.gpg;
        publicKey = ../../secrets/ij-public-key.gpg;
      };
    };
  };

  networking.hostName = "ij-desktop";

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
