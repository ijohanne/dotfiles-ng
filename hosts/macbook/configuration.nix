{ inputs, config, pkgs, lib, user, modules, ... }:

let
  network = modules.private.inventory.network { inherit lib; };
  pakhetIp = network.hosts.pakhet.ip;
  desktopApps = modules.public.lib.desktopApps;
in
{
  imports = [
    modules.public.darwin.shared.nixCaches
    modules.private.darwin.aspects.workstationSecrets
    (import modules.private.darwin.aspects.remoteBuilderClient {
      builderHost = "pakhet";
      builderIp = pakhetIp;
    })
    (import modules.public.darwin.aspects.localFlakeDeploy {
      name = "deploy-macbook";
      host = "macbook";
    })
  ];

  ids.gids.nixbld = 30000;

  system.primaryUser = user.username;

  networking.hostName = "macbook";

  users.users.${user.username} = {
    home = "/Users/${user.username}";
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  environment = {
    shells = [ pkgs.fish ];
    systemPackages = [ ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    casks =
      builtins.filter (x: x != null) (map (app: app.brewCask or null) desktopApps) ++ [ "steipete/tap/codexbar" ];

    masApps = {
      "WhatsApp" = 310633997;
      "Xcode" = 497799835;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  services.lorri.enable = true;

  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
    '';
  };

  programs.fish.enable = true;

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleInterfaceStyle = "Dark";
      AppleIconAppearanceTheme = "TintedDark";
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.swipescrolldirection" = false;
    };

    dock = {
      autohide = false;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.2;
      expose-animation-duration = 0.2;
      tilesize = 48;
      launchanim = true;
      static-only = false;
      show-recents = false;
      show-process-indicators = true;
      orientation = "bottom";
      mru-spaces = false;
      minimize-to-application = true;
      wvous-bl-corner = 4;
      wvous-br-corner = 14;
      wvous-tl-corner = 5;
      wvous-tr-corner = 12;
      persistent-apps = [
        "${pkgs.ghostty-bin}/Applications/Ghostty.app"
        "${pkgs.zed-editor}/Applications/Zed.app"
        "/Applications/Safari.app"
        "/Applications/Google Chrome.app"
        "/Applications/Notion.app"
        "/Applications/Slack.app"
        "/Applications/Mattermost.app"
        "/Applications/Discord.app"
        "/System/Applications/Messages.app"
        "/Applications/WhatsApp.app"
        "/System/Applications/FaceTime.app"
        "/Applications/Proton Mail.app"
        "/System/Applications/Music.app"
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      FXRemoveOldTrashItems = true;
      NewWindowTarget = "Other";
      NewWindowTargetPath = "file:///Users/${user.username}/Downloads/";
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = true;
    };

    spaces.spans-displays = true;

    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = false;
      ShowAMPM = true;
      ShowDate = 0;
    };

    screencapture = {
      location = "~/Downloads";
      type = "png";
      disable-shadow = true;
      show-thumbnail = false;
    };

    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Disable Ctrl+Space for "Select the previous input source"
          "60" = { enabled = false; };
          # Disable Ctrl+Option+Space for "Select next source in Input menu"
          "61" = { enabled = false; };
        };
      };
      NSGlobalDomain = {
        WebKitDeveloperExtras = true;
      };
      "com.apple.finder" = {
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        ShowRecentTags = false;
        _FXSortFoldersFirst = true;
        FXDefaultSearchScope = "SCcf";
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.screensaver" = {
        askForPassword = 1;
        askForPasswordDelay = 0;
      };

      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.print.PrintingPrefs" = {
        "Quit When Finished" = true;
      };
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      "com.apple.ImageCapture".disableHotPlug = true;
      "com.apple.commerce".AutoUpdate = true;
      "com.apple.WindowManager" = {
        HideDesktop = true;
        StandardHideDesktopIcons = true;
      };
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo ""
    echo "NOTE: If this is a fresh install, enable Proton Pass Safari extension:"
    echo "      Safari > Settings > Extensions > Enable 'Proton Pass'"
    echo ""

    # Start gpg-agent if not running
    if [ -z "$GPG_AGENT_INFO" ]; then
      gpgconf --launch gpg-agent 2>/dev/null || true
    fi
  '';


  system.stateVersion = 5;
}
