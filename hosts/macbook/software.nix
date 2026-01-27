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
    ];

    casks = [
      "google-chrome"
      "slack"
      "libreoffice"
      "discord"
      "docker-desktop"
      "proton-drive"
      "proton-mail"
      "proton-pass"
      "protonvpn"
    ];

    masApps = {
      "WhatsApp" = 310633997;
    };
  };
}
