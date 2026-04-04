{ pkgs, modules, ... }:

{
  imports = [
    modules.public.nixos.aspects.nixCli
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  services.xserver.enable = false;

  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  environment.systemPackages = with pkgs; [
    vim
    htop
    git
  ];

  nixpkgs.config.allowUnfree = true;
}
