{ inputs, config, pkgs, lib, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./services
  ];

  system.stateVersion = "22.05";

  networking = {
    hostName = "pakhet";
    useDHCP = true;
  };

  time.timeZone = "Europe/Madrid";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = lib.mkDefault 64;
    substituters = [ "https://ijohanne.cachix.org" ];
    trusted-public-keys = [ "ijohanne.cachix.org-1:oDy0m6h+CimPEcaUPaTZpEyVk6FVFpYPAXrrA9L5i9M=" ];
    # Allow __noChroot derivations (needed for screeny-frontend which uses bun)
    sandbox = "relaxed";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 180d";
  };

  nixpkgs.config.allowUnfree = true;

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

  programs.zsh.enable = true;
  programs.fish.enable = true;

  users.groups.srv = {};

  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeFunHfY3vS2izkp7fMHk2bXuaalNijYcctAF2NGc1T"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiCGBgFgwbHB+2m++ViEnhoFjww2Twvx8gXWcMvHvz3 martin@martin8412.dk"
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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeFunHfY3vS2izkp7fMHk2bXuaalNijYcctAF2NGc1T"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/pakhet.yaml;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_rsa_key"
      ];
      keyFile = "/root/.config/sops/age/keys.txt";
      generateKey = false;
    };
  };
}
