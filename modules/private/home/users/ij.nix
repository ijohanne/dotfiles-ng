{ desktop ? false }:

{ pkgs, lib, user, modules, inputs, config, ... }:

let
  desktopApps = modules.public.lib.desktopApps;
  agentBrowserPackage = inputs.nixpkgs-agent-browser.legacyPackages.${pkgs.stdenv.hostPlatform.system}.agent-browser;
in
{
  imports = [
    modules.public.homeManager.programs.openDesign
    (import modules.public.homeManager.aspects.developerBase { inherit desktop; })
  ];

  services.open-design = lib.mkIf desktop {
    enable = true;
    autoStart = true;
    localIntegration = {
      enable = true;
      codexExecutable = if pkgs.stdenv.isDarwin then "/Applications/Codex.app/Contents/Resources/codex" else null;
      agentBrowser = {
        package = agentBrowserPackage;
        managedBrowser.enable = pkgs.stdenv.isDarwin;
      };
    };
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
