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
      "assimelha/tap"
      "dicklesworthstone/tap"
      "steipete/tap"
    ];

    brews = [
      "assimelha/tap/bdui"
      "dicklesworthstone/tap/bv"
    ];

    casks = [
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
      "vibetunnel"
    ];

    masApps = {
      "WhatsApp" = 310633997;
      "Xcode" = 497799835;
    };
  };
}
