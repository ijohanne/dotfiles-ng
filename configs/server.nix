{ pkgs, lib, user, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };

  services.xserver.enable = false;

  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "8192"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
  ];

  environment.systemPackages = with pkgs; [
    ripgrep
    vim
    nixpkgs-fmt
    htop
    fish
    git
    sops
    age
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;

  users.groups.srv = {};

  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeFunHfY3vS2izkp7fMHk2bXuaalNijYcctAF2NGc1T"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiCGBgFgwbHB+2m++ViEnhoFjww2Twvx8gXWcMvHvz3 martin@martin8412.dk"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGlZ6MnFwequnPcUuM26bxcHZR/1447SL0vP3fjIkJq nix-remote-builder-macbook"
    ];
  };

  users.users.mj = {
    createHome = true;
    description = "Martin Karlsen Jensen";
    extraGroups = [ "wheel" ];
    group = "adm";
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiCGBgFgwbHB+2m++ViEnhoFjww2Twvx8gXWcMvHvz3 martin@martin8412.dk"
    ];
  };

  users.users.${user.username} = {
    createHome = true;
    description = user.name;
    extraGroups = [ "wheel" ];
    group = "adm";
    isNormalUser = true;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = user.sshKeys;
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = lib.mkDefault 64;
    substituters = [ "https://ijohanne.cachix.org" ];
    trusted-public-keys = [ "ijohanne.cachix.org-1:oDy0m6h+CimPEcaUPaTZpEyVk6FVFpYPAXrrA9L5i9M=" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 180d";
  };

  nixpkgs.config.allowUnfree = true;
}
