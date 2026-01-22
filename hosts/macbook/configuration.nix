{ inputs, config, pkgs, lib, user, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  nix.gc = {
    automatic = true;
  };

  ids.gids.nixbld = 30000;

  system.primaryUser = user.username;

  networking.hostName = "macbook";

  users.users.${user.username} = {
    home = "/Users/${user.username}";
    packages = with pkgs; [
      git
    ];
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    inputs.rust-overlay.overlays.default
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  services.lorri.enable = true;

  system.activationScripts.postActivation.text = ''
    chsh -s /run/current-system/sw/bin/fish ${user.username}

    # Start gpg-agent if not running
    if [ -z "$GPG_AGENT_INFO" ]; then
      gpgconf --launch gpg-agent 2>/dev/null || true
    fi
  '';
}
