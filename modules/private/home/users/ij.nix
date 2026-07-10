{ desktop ? false }:

{ pkgs, lib, user, modules, inputs, config, ... }:

let
  desktopApps = modules.public.lib.desktopApps;
  agentBrowserPackage = inputs.nixpkgs-agent-browser.legacyPackages.${pkgs.stdenv.hostPlatform.system}.agent-browser;
  openDesignPackage = inputs.open-design.packages.${pkgs.stdenv.hostPlatform.system}.daemon;
  openDesignPackageFixed =
    if pkgs.stdenv.isDarwin then
      openDesignPackage.overrideAttrs
        (old: {
          # better-sqlite3's Darwin build invokes Apple's libtool through node-gyp.
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.darwin.cctools ];
        })
    else
      openDesignPackage;
  openDesignBrowser = if pkgs.stdenv.isDarwin then "/usr/bin/open" else "${pkgs.xdg-utils}/bin/xdg-open";
  openDesignCodex = pkgs.writeShellScriptBin "codex" ''
    exec /Applications/Codex.app/Contents/Resources/codex "$@"
  '';
  openDesignPath = lib.concatStringsSep ":" (
    lib.optionals pkgs.stdenv.isDarwin [ "${openDesignCodex}/bin" ]
    ++ [
      "${agentBrowserPackage}/bin"
      "${config.home.profileDirectory}/bin"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]
  );
  openDesign = pkgs.writeShellScriptBin "open-design" ''
    if [ "$#" -eq 0 ]; then
      exec ${openDesignBrowser} "http://127.0.0.1:''${OD_WEB_PORT:-5174}/"
    fi

    export OD_DATA_DIR="''${OD_DATA_DIR:-$HOME/.od}"
    exec ${lib.getExe openDesignPackageFixed} "$@"
  '';
in
{
  imports = [
    inputs.open-design.homeManagerModules.default
    (import modules.public.homeManager.aspects.developerBase { inherit desktop; })
  ];

  services.open-design = lib.mkIf desktop {
    enable = true;
    package = openDesign;
    autoStart = true;
    extraEnv = lib.optionalAttrs pkgs.stdenv.isDarwin { PATH = openDesignPath; };
    webFrontend.enable = true;
  };

  home = {
    packages = lib.optionals desktop (
      [ agentBrowserPackage ]
      ++ map (app: pkgs.${app.nixPackage}) (
        builtins.filter (app: app ? nixPackage && (!pkgs.stdenv.isDarwin || !(app ? brewCask))) desktopApps
      )
    );
  };

  home.activation.importGpgKey = lib.mkIf desktop (lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '');

  home.activation.tldrUpdate = lib.hm.dag.entryAfter ([ "writeBoundary" ] ++ lib.optional desktop "importGpgKey") ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  services.gpg-agent = lib.mkIf (!pkgs.stdenv.isDarwin && desktop) {
    enable = true;
    enableSshSupport = true;
  };

  programs.fish.enable = true;
}
