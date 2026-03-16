{ inputs, config, pkgs, lib, user, ... }:

let
  deploy = import ../../configs/deploy { inherit pkgs; };
  network = import ../../configs/network.nix { inherit lib; };
  pakhetIp = network.hosts.pakhet.ip;
in
{
  imports = [
    ../../configs/secrets.nix
    ../../configs/darwin/dock
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    builders-use-substitutes = true;
    trusted-users = [ "root" "@admin" user.username ];
    substituters = [
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  nix.gc = {
    automatic = true;
  };

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = pakhetIp;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      protocol = "ssh-ng";
      sshUser = "root";
      sshKey = "/etc/nix/builder_ed25519";
      maxJobs = 64;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
  ];

  ids.gids.nixbld = 30000;

  system.primaryUser = user.username;

  networking.hostName = "macbook";

  users.users.${user.username} = {
    home = "/Users/${user.username}";
    packages = with pkgs; [
      git
      git-lfs
      (writeShellScriptBin "setup-remote-builder" ''
        echo "Setting up SSH known host for remote builder (pakhet)..."
        sudo ssh-keyscan -t ed25519 ${pakhetIp} | sudo tee -a /var/root/.ssh/known_hosts
        echo ""
        echo "Testing connection to remote builder..."
        sudo ssh -i /etc/nix/builder_ed25519 root@${pakhetIp} "echo 'Connection successful!'"
        echo ""
        echo "Remote builder setup complete."
      '')
    ];
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  environment = {
    shells = [ pkgs.fish ];
    systemPackages = [
      (deploy.mkLocalDeployScript {
        name = "deploy-macbook";
        host = "macbook";
        rebuildCmd = "darwin-rebuild switch --flake";
      })
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

  system.activationScripts.postActivation.text = ''
    echo ""
    echo "NOTE: If this is a fresh install, enable Proton Pass Safari extension:"
    echo "      Safari > Settings > Extensions > Enable 'Proton Pass'"
    echo ""

    chsh -s /run/current-system/sw/bin/fish ${user.username}

    # Start gpg-agent if not running
    if [ -z "$GPG_AGENT_INFO" ]; then
      gpgconf --launch gpg-agent 2>/dev/null || true
    fi

    # Copy remote builder SSH key to /etc/nix for nix-daemon access
    if [ -f /run/secrets/nix_remote_builder_ssh_key ]; then
      rm -f /etc/nix/builder_ed25519
      cat /run/secrets/nix_remote_builder_ssh_key > /etc/nix/builder_ed25519
      chmod 600 /etc/nix/builder_ed25519
      chown root:wheel /etc/nix/builder_ed25519
    fi

    # Copy GitHub access token to user nix config for private flake inputs
    if [ -f /run/secrets/nix_builder_access_tokens ]; then
      USER_NIX_DIR="/Users/${user.username}/.config/nix"
      mkdir -p "$USER_NIX_DIR"
      cp /run/secrets/nix_builder_access_tokens "$USER_NIX_DIR/access-tokens.conf"
      chmod 600 "$USER_NIX_DIR/access-tokens.conf"
      chown ${user.username}:staff "$USER_NIX_DIR/access-tokens.conf"
      grep -q '!include' "$USER_NIX_DIR/nix.conf" 2>/dev/null || echo '!include access-tokens.conf' >> "$USER_NIX_DIR/nix.conf"
      chown ${user.username}:staff "$USER_NIX_DIR/nix.conf"
    fi
  '';

  local.dock = {
    enable = true;
    username = user.username;
    entries = [
      { path = "${pkgs.ghostty-bin}/Applications/Ghostty.app"; }
      { path = "${pkgs.zed-editor}/Applications/Zed.app"; }
      { path = "/Applications/Safari.app"; }
      { path = "/Applications/Google Chrome.app"; }
      { path = "/Applications/Notion.app"; }
      { path = "/Applications/Slack.app"; }
      { path = "/Applications/Mattermost.app"; }
      { path = "/Applications/Discord.app"; }
      { path = "/System/Applications/Messages.app"; }
      { path = "/Applications/WhatsApp.app"; }
      { path = "/System/Applications/FaceTime.app"; }
      { path = "/Applications/Proton Mail.app"; }
      { path = "/System/Applications/Music.app"; }
    ];
  };

  system.stateVersion = 5;
}
