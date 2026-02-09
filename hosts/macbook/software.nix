{ pkgs, ... }:
{
  system.stateVersion = 5;

  environment = {
    shells = [
      pkgs.fish
    ];

    systemPackages = with pkgs; [
      fish
      ghostty-bin
    ];
  };

  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    taps = [
      "steipete/tap"
    ];

    casks = [
      "steipete/tap/codexbar"
      "steipete/tap/repobar"
      "google-chrome"
      "slack"
      "mattermost"
      "libreoffice"
      "discord"
      "docker-desktop"
      "proton-drive"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      "notion"
    ];

    masApps = {
      "WhatsApp" = 310633997;
    };
  };
}
