{ config, inputs, modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" "tcp_bbr" "it87" ];
  boot.kernelPackages = inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.blacklistedKernelModules = [ "igb" ];

  # Only a one-shot boot entry opts in; keep the known-good entry as the EFI default.
  systemd.timers.router-trial-rollback = {
    wantedBy = [ "timers.target" ];
    unitConfig.ConditionKernelCommandLine = "router_trial_boot";
    timerConfig = {
      OnBootSec = "15min";
      AccuracySec = "1s";
    };
  };
  systemd.services.router-trial-rollback = {
    unitConfig.ConditionKernelCommandLine = "router_trial_boot";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --no-block reboot";
    };
  };

  fileSystems."/" = {
    device = "/dev/nvme0n1p2";
    fsType = "btrfs";
    options = [ "subvol=nixos" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/397B-B9BF";
    fsType = "vfat";
  };

  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;

  boot.extraModulePackages = [
    config.boot.kernelPackages.it87
  ];

  systemd.settings.Manager = {
    WatchdogDevice = "/dev/watchdog";
    RuntimeWatchdogSec = "60s";
  };

  powerManagement.powertop.enable = true;
  powerManagement.cpuFreqGovernor = "conservative";
  services.thermald.enable = true;
  services.fwupd.enable = true;
}
