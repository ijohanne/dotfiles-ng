# Open Design Home Manager integration

This module imports the Home Manager module from the consumer's `inputs.open-design`
flake and adds local-agent compatibility wrappers without pinning an Open Design
version itself.

Pass the consumer's flake inputs through Home Manager `extraSpecialArgs`, then import
the module:

```nix
{
  inputs.open-design.url = "github:nexu-io/open-design";
  inputs.dotfiles.url = "github:ijohanne/dotfiles-ng";

  outputs = inputs@{ home-manager, nixpkgs, dotfiles, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        dotfiles.homeManagerModules.openDesign
        ({ pkgs, ... }: {
          services.open-design = {
            enable = true;
            autoStart = true;
            webFrontend.enable = true;

            localIntegration = {
              enable = true;
              codexExecutable = "/Applications/Codex.app/Contents/Resources/codex";
              agentBrowser = {
                package = pkgs.agent-browser;
                managedBrowser.enable = true;
              };
            };
          };
        })
      ];
    };
  };
}
```

`localIntegration.daemonPackage` defaults to the daemon package from the supplied
Open Design input. Override it when an upstream version changes its package output.
The managed browser is currently Darwin-only and remains opt-in. On Darwin, the
module also verifies its launch agents after Home Manager activation and retries a
failed bootstrap so a launchd unload/reload race cannot silently leave Open Design
offline.
