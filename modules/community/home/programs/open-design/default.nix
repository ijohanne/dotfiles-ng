{ config
, inputs
, lib
, pkgs
, ...
}:

let
  cfg = config.services.open-design;
  integration = cfg.localIntegration;
  system = pkgs.stdenv.hostPlatform.system;

  daemonPackage =
    if pkgs.stdenv.isDarwin && integration.fixDarwinSqliteBuild then
      integration.daemonPackage.overrideAttrs
        (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.darwin.cctools ];
        })
    else
      integration.daemonPackage;

  codexWrapper = pkgs.writeShellScriptBin "codex" ''
    exec ${lib.escapeShellArg integration.codexExecutable} "$@"
  '';

  nixWrapper = pkgs.writeShellScriptBin "nix" ''
    export XDG_CACHE_HOME=${lib.escapeShellArg integration.nixCache.directory}
    mkdir -p "$XDG_CACHE_HOME"
    chmod 0700 "$XDG_CACHE_HOME"
    exec ${lib.escapeShellArg integration.nixCache.executable} "$@"
  '';

  browser = integration.agentBrowser.managedBrowser;
  browserLauncher = pkgs.writeShellScript "open-design-browser" ''
    mkdir -p ${lib.escapeShellArg browser.profileDirectory}
    mkdir -p ${lib.escapeShellArg integration.agentBrowser.socketDirectory}
    chmod 0700 ${lib.escapeShellArg integration.agentBrowser.socketDirectory}
    exec ${lib.escapeShellArg browser.executable} \
      --headless=new \
      --remote-debugging-address=127.0.0.1 \
      --remote-debugging-port=${toString browser.port} \
      --user-data-dir=${lib.escapeShellArg browser.profileDirectory} \
      --no-first-run \
      --no-default-browser-check \
      about:blank
  '';

  daemonPath = lib.concatStringsSep ":" (
    lib.optional (integration.codexExecutable != null) "${codexWrapper}/bin"
    ++ lib.optional integration.nixCache.enable "${nixWrapper}/bin"
    ++ lib.optional (integration.agentBrowser.package != null) "${integration.agentBrowser.package}/bin"
    ++ [ "${config.home.profileDirectory}/bin" ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      "/run/wrappers/bin"
      "/etc/profiles/per-user/${config.home.username}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]
    ++ (cfg.extraBinPaths or [ ])
  );

  openDesignPackage = pkgs.writeShellScriptBin "open-design" ''
    if [ "$#" -eq 0 ]; then
      exec ${lib.escapeShellArg integration.uiOpener} \
        "http://127.0.0.1:''${OD_WEB_PORT:-${toString cfg.webFrontend.port}}/"
    fi

    export OD_DATA_DIR="''${OD_DATA_DIR:-${toString cfg.dataDir}}"
    exec ${lib.getExe daemonPackage} "$@"
  '';
in
{
  imports = [ inputs.open-design.homeManagerModules.default ];

  options.services.open-design.localIntegration = {
    enable = lib.mkEnableOption "local Open Design agent compatibility wrappers";

    daemonPackage = lib.mkOption {
      type = lib.types.package;
      default = inputs.open-design.packages.${system}.daemon;
      defaultText = lib.literalExpression "inputs.open-design.packages.\${pkgs.stdenv.hostPlatform.system}.daemon";
      description = "Open Design daemon package to wrap.";
    };

    fixDarwinSqliteBuild = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add Darwin cctools for better-sqlite3's node-gyp build.";
    };

    uiOpener = lib.mkOption {
      type = lib.types.str;
      default = if pkgs.stdenv.isDarwin then "/usr/bin/open" else lib.getExe' pkgs.xdg-utils "xdg-open";
      defaultText = lib.literalExpression ''if pkgs.stdenv.isDarwin then "/usr/bin/open" else lib.getExe' pkgs.xdg-utils "xdg-open"'';
      description = "Executable used by a bare open-design invocation to open the web UI.";
    };

    codexExecutable = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional complete Codex executable to expose only to Open Design.";
      example = "/Applications/Codex.app/Contents/Resources/codex";
    };

    nixCache = {
      enable = lib.mkEnableOption "an Open Design-scoped writable Nix cache" // {
        default = true;
      };

      executable = lib.mkOption {
        type = lib.types.str;
        default = "/nix/var/nix/profiles/default/bin/nix";
        description = "Nix executable used by the scoped wrapper.";
      };

      directory = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/open-design-nix-cache-${config.home.username}";
        defaultText = lib.literalExpression ''"/tmp/open-design-nix-cache-\${config.home.username}"'';
        description = "Writable XDG cache directory used by Nix in sandboxed agent runs.";
      };
    };

    agentBrowser = {
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "agent-browser package exposed to Open Design and installed in the user profile.";
      };

      socketDirectory = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/open-design-agent-browser-${config.home.username}";
        defaultText = lib.literalExpression ''"/tmp/open-design-agent-browser-\${config.home.username}"'';
        description = "Writable agent-browser control socket directory for sandboxed runs.";
      };

      managedBrowser = {
        enable = lib.mkEnableOption "a loopback-only managed Chrome CDP service";

        executable = lib.mkOption {
          type = lib.types.str;
          default = if pkgs.stdenv.isDarwin then "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" else "";
          defaultText = lib.literalExpression ''if pkgs.stdenv.isDarwin then "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" else ""'';
          description = "Chrome-compatible executable launched outside the Codex workspace sandbox.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 9223;
          description = "Loopback Chrome DevTools Protocol port used by agent-browser.";
        };

        profileDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.stateHome}/open-design-browser";
          defaultText = lib.literalExpression ''"\${config.xdg.stateHome}/open-design-browser"'';
          description = "Isolated Chrome profile used by the managed browser.";
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && integration.enable) (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !browser.enable || pkgs.stdenv.isDarwin;
          message = "services.open-design.localIntegration.agentBrowser.managedBrowser currently supports Darwin only.";
        }
        {
          assertion = !browser.enable || integration.agentBrowser.package != null;
          message = "A managed Open Design browser requires services.open-design.localIntegration.agentBrowser.package.";
        }
        {
          assertion = !browser.enable || browser.executable != "";
          message = "A managed Open Design browser requires a browser executable.";
        }
      ];

      services.open-design = {
        package = openDesignPackage;
        extraEnv = {
          PATH = daemonPath;
        }
        // lib.optionalAttrs browser.enable {
          AGENT_BROWSER_CDP = toString browser.port;
          AGENT_BROWSER_SOCKET_DIR = integration.agentBrowser.socketDirectory;
        };
      };

      home.packages = lib.optional (integration.agentBrowser.package != null) integration.agentBrowser.package;
    }

    (lib.mkIf (browser.enable && pkgs.stdenv.isDarwin) {
      launchd.agents.open-design-browser = {
        enable = true;
        config = {
          ProgramArguments = [ "${browserLauncher}" ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Background";
          StandardOutPath = "${cfg.dataDir}/open-design-browser.out.log";
          StandardErrorPath = "${cfg.dataDir}/open-design-browser.err.log";
        };
      };
    })
  ]);
}
