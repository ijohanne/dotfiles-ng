{ pkgs, lib, users, modules, ... }:

{
  imports = [
    (import modules.public.nixos.aspects.gcPolicy { })
    ../../shared/nix-caches.nix
    ../profiles/system/base
  ];

  services.openssh.extraConfig = ''
    StreamLocalBindUnlink yes
  '';

  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "8192"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
  ];

  environment.systemPackages = with pkgs; [
    ripgrep
    nixpkgs-fmt
    fish
    sops
    age
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;

  users.groups.srv = { };

  users.users = lib.mapAttrs
    (_: u: {
      createHome = true;
      description = u.name;
      extraGroups = [ "wheel" ];
      group = "adm";
      isNormalUser = true;
      shell = pkgs.${u.shell};
      openssh.authorizedKeys.keys = u.sshKeys;
    })
    users // {
    root = {
      initialHashedPassword = "";
      openssh.authorizedKeys.keys =
        lib.concatMap (u: u.sshKeys) (lib.attrValues users)
          ++ [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGlZ6MnFwequnPcUuM26bxcHZR/1447SL0vP3fjIkJq nix-remote-builder-macbook"
        ];
    };
  };

  nix.settings = {
    max-jobs = lib.mkDefault 64;
    trusted-users = [ "@wheel" ];
  };

}
