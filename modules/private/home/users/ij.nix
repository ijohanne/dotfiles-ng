{ desktop ? false }:

{ pkgs, lib, user, modules, inputs, ... }:

let
  desktopApps = modules.public.lib.desktopApps;
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
  openDesign = pkgs.writeShellScriptBin "open-design" ''
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
    webFrontend.enable = true;
  };

  home = {
    packages = lib.optionals desktop (
      map (app: pkgs.${app.nixPackage}) (
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
